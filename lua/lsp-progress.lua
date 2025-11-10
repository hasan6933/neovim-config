-- =================================================================
-- Enhanced LSP Progress Handler
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

---@class LspProgressStatus
---@field client string
---@field title string
---@field percentage number
---@field message string
---@field active boolean

---@class LspProgressHandlerModule: table
local M = {}

---@type string[]
local spinners = { "◜ ", "◠ ", "◝ ", "◞ ", "◡ ", "◟ " }
local SPINNER_COUNT = #spinners

---@type table<string|integer, LspProgressCacheEntry>
local progress_cache = {}

---Show notification using Snacks notifier
---@param content string
---@param id string
---@param is_end boolean
local function show_notification(content, id, is_end)
	Snacks.notifier.notify(content, "info", {
		icon = " ",
		id = id,
		timeout = is_end and 1800 or 0,
		title = "LSP Progress",
	})
end

---Extract work progress from message string
---@param message string|nil
---@return integer|nil done The number of completed items, or nil if not found
---@return integer|nil total The total number of items, or nil if not found
local function extract_work_progress(message)
	if not message then
		return nil, nil
	end

	-- Try different patterns
	local patterns = {
		"^(%d+)/(%d+)", -- "5/100"
		"^(%d+) of (%d+)", -- "5 of 100"
		"^Processing file (%d+) of (%d+)", -- "Processing file 5 of 100"
		"(%d+) items processed", -- "5 items processed"
	}

	for _, pattern in ipairs(patterns) do
		local done, total = message:match(pattern)
		if done then
			-- Fixed: Valid Lua syntax with proper type conversion
			return tonumber(done), total and tonumber(total) --[[@as integer]]
		end
	end

	return nil, nil
end

---Clean up notification by ID
---@param id string
local function cleanup_notification(id)
	-- Fixed: Correctly check if Snacks and hide method exist
	if Snacks and Snacks.notifier and type(Snacks.notifier.hide) == "function" then
		Snacks.notifier.hide(id)
	end
end

---Main LSP progress handler
---@param result {token: string|integer, value: {kind: "begin"|"report"|"end", title?: string, message?: string, percentage?: number}}
---@param ctx {client_id: integer}
vim.lsp.handlers["$/progress"] = function(_, result, ctx)
	local client = vim.lsp.get_client_by_id(ctx.client_id)
	if not client then
		return
	end

	local token = result.token
	local progress = result.value
	local server_name = client.name or "LSP Server"

	if not progress or not progress.kind then
		return
	end

	local cache_entry = progress_cache[token]

	if progress.kind == "begin" then
		cache_entry = {
			spinner_idx = 1,
			title = progress.title or "",
			message = progress.message or "",
			percentage = 0,
			work_done = 0,
			total_work = 0,
			report_count = 0,
			start_time = vim.uv.hrtime(),
			client_id = ctx.client_id,
			server_name = server_name,
		}
		progress_cache[token] = cache_entry

		-- Extract progress from initial message
		if progress.message then
			local done, total = extract_work_progress(progress.message)
			if done and total then
				cache_entry.work_done = done
				cache_entry.total_work = total
				cache_entry.percentage = math.min((done / total) * 100, 100) ---@as integer
			end
		end

		-- Show initial notification immediately
		local notification_id = "lsp_progress_" .. tostring(token)
		local spinner = spinners[1]
		local components = { spinner, "[" .. server_name .. "]" }

		-- Fixed: Removed redundant nil check
		if cache_entry.title ~= "" then
			components[#components + 1] = cache_entry.title
		end

		if cache_entry.message ~= "" then
			components[#components + 1] = cache_entry.message
		end

		-- Fixed: Use calculated percentage instead of hardcoded 0%
		components[#components + 1] = string.format("(%.0f%%)", cache_entry.percentage)
		local message_content = table.concat(components, " ")
		show_notification(message_content, notification_id, false)
	elseif not cache_entry then
		return
	end

	if progress.kind == "report" then
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
					cache_entry.percentage = math.min((cache_entry.work_done / cache_entry.total_work) * 100, 100)
				end
			end
		end

		if progress.percentage then
			cache_entry.percentage = progress.percentage
		else
			local report_progress = math.min(cache_entry.report_count * 5, 50)
			local elapsed_ms = (vim.uv.hrtime() - cache_entry.start_time) / 1000000
			local time_progress = math.min(elapsed_ms / 600, 50)
			cache_entry.percentage = math.min(report_progress + time_progress, 99)
		end
	end

	if progress.kind == "end" then
		cache_entry.spinner_idx = 1
		cache_entry.message = progress.message or cache_entry.message
		cache_entry.percentage = 100

		if cache_entry.total_work and cache_entry.total_work > 0 then
			cache_entry.work_done = cache_entry.total_work
		end
	end

	-- Generate notification content
	local notification_id = "lsp_progress_" .. tostring(token)
	local spinner = progress.kind == "end" and "✓ " or spinners[cache_entry.spinner_idx]
	local percentage = cache_entry.percentage or 0
	local message = cache_entry.message
	local lsp_title = cache_entry.title

	local components = { spinner, "[" .. server_name .. "]" }

	if lsp_title and lsp_title ~= "" then
		components[#components + 1] = lsp_title
	end

	if cache_entry.total_work and cache_entry.total_work > 0 then
		components[#components + 1] = string.format("%d/%d", cache_entry.work_done, cache_entry.total_work)
	elseif message and message ~= "" then
		components[#components + 1] = message
	end

	components[#components + 1] = string.format("(%.0f%%)", percentage)

	local message_content = table.concat(components, " ")

	if progress.kind == "end" then
		show_notification(message_content, notification_id, true)

		-- Clean up after delay
		local timer = vim.uv.new_timer()
		if timer then
			timer:start(
				3100,
				0,
				vim.schedule_wrap(function()
					cleanup_notification(notification_id)
					progress_cache[token] = nil
					if timer and not timer:is_closing() then
						timer:close()
					end
				end)
			)
		end
	else
		show_notification(message_content, notification_id, false)
	end
end

---Function to cleanup all progress
function M.cleanup()
	for token in pairs(progress_cache) do
		progress_cache[token] = nil
	end
end

-- Cleanup on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = M.cleanup,
})

return M
