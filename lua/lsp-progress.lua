local M = {}

local snacks = require("snacks")

-- Storage to keep track of the last message/percentage for specific tokens
local progress_cache = {}

function M.setup()
	-- Handler signature: err, result, ctx
	vim.lsp.handlers["$/progress"] = function(_, result, ctx)
		local value = result and result.value
		if not value then
			return
		end

		local token = result.token
		local id = tostring(token)

		-- 1. Get the LSP Client Name
		local client = vim.lsp.get_client_by_id(ctx.client_id)
		local client_name = client and client.name or "LSP"

		-- 2. Retrieve or initialize cached data
		local data = progress_cache[id] or { message = "Working...", percentage = "" }

		-- 3. Update data based on new value
		if value.message then
			data.message = value.message
		end

		if value.percentage then
			data.percentage = string.format(" %d%%", value.percentage)
		end

		-- Handle Completion
		local done = value.kind == "end"
		if done then
			data.message = value.message or "Complete"
			data.percentage = ""
		end

		-- Store back in cache
		progress_cache[id] = data

		-- 4. Format: [LSP Name] message percentage
		-- This ensures client_name is wrapped in brackets and precedes the message
		local msg_body = string.format("[%s] %s%s", client_name, data.message, data.percentage)

		-- 5. Construct Options
		local opts = {
			id = id,
			title = "", -- EMPTY TITLE: Forces the spinner to sit inline with the message body
			level = vim.log.levels.INFO,
			timeout = done and 2000 or false,
		}

		if done then
			opts.icon = " "
			progress_cache[id] = nil
		else
			opts.loading = true -- Renders the Spinner icon
		end

		-- 6. Send Notification
		snacks.notify(msg_body, opts)
	end
end

return M
