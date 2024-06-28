M = {}
local ollama_client = require("ollama-pilot.client")
local stream = require("ollama-pilot.stream")
local prompt_templates = require("ollama-pilot.prompts")
local context = require("ollama-pilot.context")
local config = require("ollama-pilot.config")

local get_visual_selection_text = function()
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    local line_start = vstart[2]
    local line_end = vend[2]

    print("Line start/end", line_start, line_end)
    local lines = vim.fn.getline(line_start, line_end)
    if type(lines) == "string" then
        return lines
    end

    local text = ""
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, line in ipairs(lines) do
        text = text .. line .. "\n"
    end
    return text
end

-- returns a stream that will update the text in the buffer in real time when written to
local create_popup = function()
    local buf = vim.api.nvim_create_buf(false, true)

    local text = ""
    local text_stream = stream:new(function(token)
        text = text .. token
        local lines = {}
        for line in text:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        vim.schedule(function()
            vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
        end)
    end)

    local cfg = config.get_config()
    local display_opts = {
        relative = cfg.popup.relative,
        row = cfg.popup.row,
        col = cfg.popup.col,
        width = cfg.popup.width,
        height = cfg.popup.height,
        style = cfg.popup.style,
        focusable = false,
    }

    local buffer_context = context:new()
    local win = vim.api.nvim_open_win(buf, false, display_opts)
    local group = vim.api.nvim_create_augroup('ollama-explain-popup', { clear = true })
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'BufLeave' }, {
        desc = 'close ollama window',
        group = group,
        callback = function()
            vim.api.nvim_win_close(win, true)
            vim.api.nvim_del_augroup_by_id(group)
            buffer_context:send_cancel()
        end
    })
    return text_stream, buffer_context
end

-- opens 2 windows where one is used just for displaying the chat
-- another window where you submit your text
local open_chat_window = function()
    local history_buf = vim.api.nvim_create_buf(false, true)
    -- vim.bo[history_buf].modifiable = false
    vim.bo[history_buf].readonly = true
    local input_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[input_buf].readonly = true

    local cur_line = 0
    local text_stream = stream:new(function(chunk)
        local frozen_cur_line = cur_line
        if type(chunk) == "table" then
            local frozen_end_line = cur_line + #chunk
            cur_line = cur_line + #chunk
            -- vim.schedule(function()
            vim.api.nvim_buf_set_lines(history_buf, frozen_cur_line, frozen_end_line, false, chunk)
            -- end)
            return
        end
        -- otherwise it's just a token
        if chunk == "\n" or string.find(chunk, "\n") ~= nil then
            cur_line = frozen_cur_line + 1
            return
        end
        vim.schedule(function()
            print(frozen_cur_line)
            local line_text = vim.api.nvim_buf_get_lines(history_buf, frozen_cur_line, frozen_cur_line + 1, false)[1] or
                ""
            line_text = line_text .. chunk
            vim.api.nvim_buf_set_lines(history_buf, frozen_cur_line, frozen_cur_line + 1, false, { line_text })
        end)
    end)

    local nvim_width = vim.o.columns
    local nvim_height = vim.o.lines
    local history_display_opts = {
        split = "right",
        focusable = true,
        width = math.floor(nvim_width * 0.4)
    }
    local input_display_opts = {
        split = "below",
        height = math.floor(nvim_height * 0.4)
    }
    local chat_history = vim.api.nvim_open_win(history_buf, true, history_display_opts)
    local chat_input = vim.api.nvim_open_win(input_buf, true, input_display_opts)

    vim.keymap.set("n", "<CR>", function()
        local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
        vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {})
        local approx_win_width = vim.api.nvim_win_get_width(chat_history) - 10

        local request_text = ""
        local right_aligned_lines = {}
        for _, line in ipairs(lines) do
            request_text = request_text .. line
            local aligned_line = string.rep(" ", approx_win_width - #line) .. line
            table.insert(right_aligned_lines, aligned_line)
        end

        local ctx = context:new()
        text_stream:write(right_aligned_lines)
        ollama_client.get_response(request_text, text_stream, ctx, true)
    end, { buffer = input_buf })
end

---Grabs the context (code) above and below the current position to aid in autocomplete
---
---@param context_size number how many lines above and below current position to use as context (x above and x below)
---@return string above string that contains the code x lines above current position
---@return string current string that contains the code in the current line (usually incomplete)
---@return string below string that contains the code x lines below current position
local get_local_context = function(context_size)
    local above = ""
    local current = ""
    local below = ""

    local win = vim.api.nvim_get_current_win()
    local cursor_position = vim.api.nvim_win_get_cursor(win)
    local current_line_num = cursor_position[1]

    local buf = vim.api.nvim_get_current_buf()
    local lines_above = vim.api.nvim_buf_get_lines(buf, current_line_num - context_size, current_line_num - 1, false)
    local lines_current = vim.api.nvim_buf_get_lines(buf, current_line_num - 1, current_line_num, false)
    local lines_below = vim.api.nvim_buf_get_lines(buf, current_line_num, current_line_num + 1 + context_size, false)

    for _, line in ipairs(lines_above) do
        above = above .. line .. "\n"
    end
    for _, line in ipairs(lines_current) do
        current = current .. line .. "\n"
    end
    for _, line in ipairs(lines_below) do
        below = below .. line .. "\n"
    end

    return above, current, below
end

M.explain_selection = function()
    local text = get_visual_selection_text()
    local prompt = prompt_templates.explain(text)
    local buf_stream, buf_context = create_popup()
    ollama_client.get_response(prompt, buf_stream, buf_context)
end


M.chat = function()
    -- TODO: lots more enhancements to do here
    -- chat history and maybe agent integration with cht.sh

    open_chat_window()
end

M.autocomplete_suggestion = function()
    local buf = vim.api.nvim_get_current_buf()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor_pos[1] - 1
    local column_num = cursor_pos[2]
    local ns = vim.api.nvim_create_namespace("virtual_autocomplete")
    local virt_text = ""

    local cfg = config.get_config()
    local above, current, below = get_local_context(cfg.autocomplete.context_line_size)
    local prompt = prompt_templates.autocomplete(above, current, below)
    local ctx = context:new()
    local tok_stream = stream:new(function(tok)
            local freeze_text = virt_text .. tok
            virt_text = freeze_text
            vim.schedule(function()
                vim.api.nvim_buf_set_extmark(0, ns, line_num, column_num, {
                    virt_text = { { freeze_text, "Comment" } },
                    virt_text_pos = "overlay"
                })
            end)
        end)

    vim.keymap.set("i", "<Tab>", function()
        vim.api.nvim_put({ virt_text }, "", true, true)
    end, { buffer = buf })

    vim.api.nvim_create_autocmd({ "InsertLeave", "InsertLeavePre", "CursorMovedI" }, {
        group = vim.api.nvim_create_augroup('OllamaCancelAutocomplete', { clear = true }),
        callback = function()
            ctx:send_cancel()
            vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
            local exists = vim.api.nvim_get_keymap("i")["<Tab>"]
            if exists then
                vim.keymap.del("i", "<Tab>")
            end
        end,
    })

    ollama_client.get_response(prompt, tok_stream, ctx)
end

return M
