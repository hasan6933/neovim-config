local M = {}
local spinners = { "◜ ", "◠ ", "◝ ", "◞ ", "◡ ", "◟ " }
local cache = {}

local function extract_work(msg)
	if not msg then
		return nil, nil
	end
	local d, t = msg:match("^(%d+)/(%d+)")
		or msg:match("^(%d+) of (%d+)")
		or msg:match("Processing file (%d+) of (%d+)")
		or msg:match("(%d+) items processed")
	return d and tonumber(d), t and tonumber(t)
end

local function notify(msg, id, timeout)
	Snacks.notifier.notify(msg, "info", { icon = " ", id = id, timeout = timeout or 0, title = "LSP Progress" })
end

local function hide(id)
	local n = Snacks.notifier
	if n and type(n.hide) == "function" then
		n.hide(id)
	end
end

vim.lsp.handlers["$/progress"] = function(_, result, ctx)
	local client = vim.lsp.get_client_by_id(ctx.client_id)
	if not client then
		return
	end

	local val, token, name = result.value, result.token, client.name
	local kind, id = val.kind, "lsp_progress_" .. token
	local e = cache[token]

	if kind == "begin" then
		e = {
			spinner_idx = 1,
			title = val.title or "",
			message = val.message or "",
			percentage = 0,
			work_done = 0,
			total_work = 0,
			report_count = 0,
			start_time = vim.uv.hrtime(),
			client_id = ctx.client_id,
			server_name = name,
		}
		cache[token] = e
		local d, t = extract_work(val.message)
		if d and t then
			e.work_done, e.total_work, e.percentage = d, t, math.min(d / t * 100, 100)
		end
	elseif not e then
		return
	elseif kind == "report" then
		e.spinner_idx = (e.spinner_idx % #spinners) + 1
		e.report_count = e.report_count + 1
		if val.message then
			e.message = val.message
			local d, t = extract_work(val.message)
			if d then
				e.work_done = d
				if t then
					e.total_work = t
				end
				if e.total_work > 0 then
					e.percentage = math.min(d / e.total_work * 100, 100)
				end
			end
		end
		if val.percentage then
			e.percentage = val.percentage
		else
			local t = (vim.uv.hrtime() - e.start_time) / 1e6
			e.percentage = math.min(e.report_count * 5 + math.min(t / 600, 50), 99)
		end
	elseif kind == "end" then
		e.spinner_idx, e.message, e.percentage = 1, val.message or e.message, 100
		if e.total_work > 0 then
			e.work_done = e.total_work
		end
	end

	local spinner = kind == "end" and "✓ " or spinners[e.spinner_idx]
	local parts = { spinner, "[" .. name .. "]" }

	if e.title ~= "" then
		parts[#parts + 1] = e.title
	end
	if e.total_work > 0 then
		parts[#parts + 1] = string.format("%d/%d", e.work_done, e.total_work)
	elseif e.message ~= "" then
		parts[#parts + 1] = e.message
	end
	parts[#parts + 1] = string.format("(%.0f%%)", e.percentage)

	local msg = table.concat(parts, " ")

	if kind == "end" then
		notify(msg, id, 1800)
		local timer = vim.uv.new_timer()
		if timer then
			timer:start(
				3100,
				0,
				vim.schedule_wrap(function()
					hide(id)
					cache[token] = nil
					if not timer:is_closing() then
						timer:close()
					end
				end)
			)
		end
	else
		notify(msg, id)
	end
end

function M.cleanup()
	for k in pairs(cache) do
		cache[k] = nil
	end
end

vim.api.nvim_create_autocmd("VimLeavePre", { callback = M.cleanup })
return M
