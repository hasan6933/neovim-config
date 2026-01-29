-- =================================================================
-- Enhanced LSP Progress Handler (Fixed Brackets + Duplication)
-- =================================================================

---@class LspProgressCacheEntry
---@field spinner_idx integer
---@field title string
---@field message string
---@field percentage number
---@field work_done integer
---@field total_work integer|nil
---@field report_count integer
---@field start_time number
---@field client_id integer
---@field server_name string

---@class LspProgressHandlerModule: table
local M = {}

---@type string[]
local spinners = { "◜ ", "◠ ", "◝ ", "◞ ", "◡ ", "◟ " }
local SPINNER_COUNT = #spinners

---@type table<string|integer, LspProgressCacheEntry>
local progress_cache = {}

---Generate notification ID from token
---@param token string|integer
---@return string
local function get_notification_id(token)
	return "lsp_progress_" .. tostring(token)
end

---Show notification using Snacks notifier
---@param content string
---@param id string
---@param is_end boolean
local function show_notification(content, id, is_end)
	if not (Snacks and Snacks.notifier) then
		return
	end
	Snacks.notifier.notify(content, "info", {
		icon = " ",
		id = id,
		timeout = is_end and 1800 or 0,
		title = "LSP Progress",
	})
end

---Clean up notification by ID
---@param id string
local function cleanup_notification(id)
	if Snacks and Snacks.notifier and type(Snacks.notifier.hide) == "function" then
		Snacks.notifier.hide(id)
	end
end

---Extract work progress from message string
---@param message string|nil
---@return integer|nil done
---@return integer|nil total
local function extract_work_progress(message)
	if not message then
		return nil, nil
	end

	local patterns = {
		"^(%d+)/(%d+)",
		"^(%d+) of (%d+)",
		"^Processing file (%d+) of (%d+)",
		"(%d+) items processed",
	}

	for _, pattern in ipairs(patterns) do
		local done, total = message:match(pattern)
		if done then
			return tonumber(done), total and tonumber(total)
		end
	end
	return nil, nil
end

---Check if message is redundant with title (fixes jdtls "Indexing Indexing")
---@param title string
---@param message string
---@return boolean
local function is_message_redundant(title, message)
	if title == "" or message == "" then
		return false
	end

	-- Normalize: remove trailing dots, spaces, and ellipses
	local norm_title = title:gsub("[%.…%s]+$", "")
	local norm_message = message:gsub("[%.…%s]+$", "")

	if norm_message == norm_title then
		return true
	end

	local escaped_title = vim.pesc(norm_title)
	if norm_message:find("^" .. escaped_title .. "[%.…%s]*$") then
		return true
	end

	return false
end

---Get reliable server name with fallbacks (critical fix for jdtls)
---@param client table
---@return string
local function get_reliable_server_name(client)
	-- Try client.name first (might be nil/empty for jdtls)
	local name = client.name
	if name and name ~= "" then
		return name
	end

	-- Try client.server_info.name (jdtls often populates this)
	if client.server_info and client.server_info.name and client.server_info.name ~= "" then
		return client.server_info.name
	end

	-- Fallback to client id as last resort
	return "LSP-" .. tostring(client.id)
end

---Build notification content from cache entry
---@param cache_entry LspProgressCacheEntry
---@param is_end boolean
---@return string
local function build_notification_content(cache_entry, is_end)
	local spinner = is_end and "✓ " or spinners[cache_entry.spinner_idx]
	local percentage = math.min(cache_entry.percentage or 0, 100)

	-- CRITICAL FIX: Ensure server name is NEVER empty for bracket display
	local server_display = cache_entry.server_name ~= "" and cache_entry.server_name or "LSP"
	local components = { spinner, "[" .. server_display .. "]" }

	if cache_entry.title ~= "" then
		table.insert(components, cache_entry.title)
	end

	if cache_entry.total_work and cache_entry.total_work > 0 then
		table.insert(components, string.format("%d/%d", cache_entry.work_done, cache_entry.total_work))
	elseif cache_entry.message ~= "" and not is_message_redundant(cache_entry.title, cache_entry.message) then
		table.insert(components, cache_entry.message)
	end

	table.insert(components, string.format("(%.0f%%)", percentage))
	return table.concat(components, " ")
end

---Main LSP progress handler
---@param _ any
---@param result {token: string|integer, value: {kind: "begin"|"report"|"end", title?: string, message?: string, percentage?: number}}
---@param ctx {client_id: integer}
vim.lsp.handlers["$/progress"] = function(_, result, ctx)
	local client = vim.lsp.get_client_by_id(ctx.client_id)
	if not client then
		return
	end

	local token = result.token
	local progress = result.value
	local kind = progress and progress.kind
	if not kind then
		return
	end

	local cache_entry = progress_cache[token]
	local notification_id = get_notification_id(token)

	-- Initialize on 'begin' - capture server name ONCE with robust fallbacks
	if kind == "begin" then
		local server_name = get_reliable_server_name(client)

		cache_entry = {
			spinner_idx = 1,
			title = progress.title or "",
			message = progress.message or "",
			percentage = 0,
			work_done = 0,
			total_work = nil,
			report_count = 0,
			start_time = vim.uv.hrtime(),
			client_id = ctx.client_id,
			server_name = server_name, -- Guaranteed non-empty
		}
		progress_cache[token] = cache_entry

		-- Extract initial progress from message
		if progress.message then
			local done, total = extract_work_progress(progress.message)
			if done and total then
				cache_entry.work_done = done
				cache_entry.total_work = total
				cache_entry.percentage = math.min((done / total) * 100, 100)
			end
		end
	end

	-- Must have cache entry for 'report' or 'end'
	if not cache_entry then
		return
	end

	-- Update state based on progress kind
	if kind == "report" then
		cache_entry.spinner_idx = (cache_entry.spinner_idx % SPINNER_COUNT) + 1
		cache_entry.report_count = cache_entry.report_count + 1

		if progress.message then
			cache_entry.message = progress.message
			local done, total = extract_work_progress(progress.message)
			if done then
				cache_entry.work_done = done
				if total then
					cache_entry.total_work = total
				end
				if cache_entry.total_work and cache_entry.total_work > 0 then
					cache_entry.percentage = math.min((done / cache_entry.total_work) * 100, 100)
				end
			end
		end

		if progress.percentage then
			cache_entry.percentage = progress.percentage
		else
			local report_progress = math.min(cache_entry.report_count * 5, 50)
			local elapsed_ms = (vim.uv.hrtime() - cache_entry.start_time) / 1e6
			local time_progress = math.min(elapsed_ms / 600, 50)
			cache_entry.percentage = math.min(report_progress + time_progress, 99)
		end
	elseif kind == "end" then
		cache_entry.spinner_idx = 1
		cache_entry.message = progress.message or cache_entry.message
		cache_entry.percentage = 100
		if cache_entry.total_work and cache_entry.total_work > 0 then
			cache_entry.work_done = cache_entry.total_work
		end
	end

	-- Show notification using stored server_name (guaranteed non-empty)
	local content = build_notification_content(cache_entry, kind == "end")
	show_notification(content, notification_id, kind == "end")

	-- Cleanup on completion
	if kind == "end" then
		local timer = vim.uv.new_timer()
		if timer then
			timer:start(
				3100,
				0,
				vim.schedule_wrap(function()
					if not timer:is_closing() then
						cleanup_notification(notification_id)
						progress_cache[token] = nil
						timer:close()
					end
				end)
			)
		end
	end
end

---Function to cleanup all progress
function M.cleanup()
	for token in pairs(progress_cache) do
		local id = get_notification_id(token)
		cleanup_notification(id)
		progress_cache[token] = nil
	end
end

-- Cleanup on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = M.cleanup,
})

return M
