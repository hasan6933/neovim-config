-- =================================================================
-- Enhanced LSP Progress Handler
-- =================================================================

local M = {}
local spinners = { "◜ ", "◠ ", "◝ ", "◞ ", "◡ ", "◟ " }
local progress_cache = {}

local function show_notification(content, id, is_end)
    Snacks.notifier.notify(content, "info", {
        icon = "",
        id = id,
        timeout = is_end and 1800 or 0, -- Changed to 0 for immediate display
        title = "LSP Progress",
    })
end

local function extract_work_progress(message)
    if not message then
        return nil, nil
    end

    -- Try different patterns
    local patterns = {
        "(%d+)/(%d+)",                    -- "5/100"
        "(%d+) of (%d+)",                 -- "5 of 100"
        "Processing file (%d+) of (%d+)", -- "Processing file 5 of 100"
    }

    for _, pattern in ipairs(patterns) do
        local done, total = message:match(pattern)
        if done and total then
            return tonumber(done), tonumber(total)
        end
    end

    -- Single number pattern
    local done_only = message:match("(%d+) items processed")
    if done_only then
        return tonumber(done_only), nil
    end

    return nil, nil
end

local function cleanup_notification(id)
    if pcall(function()
            return Snacks.notifier
        end) and Snacks and Snacks.notifier and Snacks.notifier.hide then
        Snacks.notifier.hide(id)
    end
end

-- Main LSP progress handler
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
        progress_cache[token] = {
            spinner_idx = 1,
            title = progress.title or "",
            message = progress.message or "",
            percentage = 0,
            work_done = 0,
            total_work = 0,
            report_count = 0,
            start_time = vim.loop.hrtime(),
            client_id = ctx.client_id,
            server_name = server_name,
        }
        cache_entry = progress_cache[token]

        -- Extract progress from initial message
        if progress.message then
            local done, total = extract_work_progress(progress.message)
            if done and total then
                cache_entry.work_done = done
                cache_entry.total_work = total
                if total > 0 then
                    cache_entry.percentage = math.min((done / total) * 100, 100)
                end
            end
        end

        -- Show initial notification immediately
        local notification_id = "lsp_progress_" .. tostring(token)
        local spinner = spinners[1]
        local components = { spinner, "[" .. server_name .. "]" }

        if cache_entry.title and cache_entry.title ~= "" then
            table.insert(components, cache_entry.title)
        end

        if cache_entry.message and cache_entry.message ~= "" then
            table.insert(components, cache_entry.message)
        end

        table.insert(components, "(0%)")
        local message_content = table.concat(components, " ")
        show_notification(message_content, notification_id, false)
    elseif not cache_entry then
        return
    end

    if progress.kind == "report" then
        cache_entry.spinner_idx = (cache_entry.spinner_idx % #spinners) + 1
        cache_entry.report_count = (cache_entry.report_count or 0) + 1

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
            local elapsed_ms = (vim.loop.hrtime() - cache_entry.start_time) / 1000000
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
    local spinner = progress.kind == "end" and "✓ " or (spinners[cache_entry.spinner_idx] or " ")
    local percentage = cache_entry.percentage or 0
    local message = cache_entry.message
    local lsp_title = cache_entry.title

    local components = { spinner, "[" .. server_name .. "]" }

    if lsp_title and lsp_title ~= "" then
        table.insert(components, lsp_title)
    end

    if cache_entry.total_work and cache_entry.total_work > 0 then
        table.insert(components, string.format("%d/%d", cache_entry.work_done, cache_entry.total_work))
    elseif message and message ~= "" then
        table.insert(components, message)
    end

    table.insert(components, string.format("(%.0f%%)", percentage))

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

-- Function to get current progress status
function M.get_progress_status()
    local status = {}
    for token, entry in pairs(progress_cache) do
        status[token] = {
            client = entry.server_name,
            title = entry.title,
            percentage = entry.percentage,
            message = entry.message,
            active = (entry.percentage or 0) < 100,
        }
    end
    return status
end

-- Function to cleanup all progress
function M.cleanup()
    for token, _ in pairs(progress_cache) do
        progress_cache[token] = nil
    end
end

-- Cleanup on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = M.cleanup,
})

return M
