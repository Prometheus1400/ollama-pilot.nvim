M = {}

local config = require("ollama-pilot.config")
local ollama = require("ollama-pilot.ollama")
local uv = vim.loop
local json = vim.json

M.get_response = function(prompt, buf_stream, buf_context, newline, model, token_delay)
    if not ollama:is_active() then
        ollama:start()
    end
    local cfg = config.get_config()
    model = model or cfg.model
    token_delay = token_delay or cfg.token_delay
    local url = "http://localhost:" .. cfg.ollama_port .. "/api/generate"
    local curl_output = uv.new_pipe(true)

    local payload = {
        model = model,
        prompt = prompt
    }
    local payload_string = json.encode(payload)
    local handle = nil
    handle, _ = uv.spawn("curl", {
        args = { url, "-X", "POST", "-H", "Content-Type: application/json", "-d", payload_string },
        stdio = { nil, curl_output, nil }
    }, function(code, signal)
        if handle and handle:is_active() then
            handle:close()
            if code ~= 0 then
                print("curl process failed with code", code, " and signal", signal)
            end
        end
    end)

    local token_buffer = {}
    local token_emitter = uv.new_timer()
    local token_emitter_logic = function()
        if #token_buffer == 0 then
            token_emitter:stop()
            if newline then
                buf_stream:write("\n")
            end
            return
        end
        local tok = table.remove(token_buffer, 1)
        print("emitting:", tok)
        buf_stream:write(tok)
    end
    local buffered = ""
    uv.read_start(curl_output, function(err, data)
        assert(not err, err)

        if data == nil then
            curl_output:close()
            return
        end

        local lines = {}
        local first_line = true
        for line in data:gmatch("[^\n]+") do
            if first_line then
                line = buffered .. line
                buffered = ""
                first_line = false
            end
            if string.sub(line, #line) ~= "}" then
                buffered = line
            else
                table.insert(lines, line)
            end
        end

        for _, line in ipairs(lines) do
            local dataTable = vim.json.decode(line)
            local token = tostring(dataTable.response)
            table.insert(token_buffer, token)
            if not token_emitter:is_active() then
                token_emitter:start(token_delay, token_delay, token_emitter_logic)
            end
        end
    end)

    buf_context:register_callback_on_cancel(function()
        -- need to close the pipe, and stop the timer
        if handle and handle:is_active() then
            handle:close()
        end
        if curl_output:is_active() then
            curl_output:close()
        end
        token_buffer = {}
        if token_emitter:is_active() then
            token_emitter:stop()
            token_emitter:close()
        end
    end)
end

M.test = function()
    -- print(vim.inspect(cfg))
    -- local response = ""
    -- local my_stream = stream:new(function(token)
    --     response = response .. token
    --     io.write(token)
    -- end)

    -- M.get_response("llama3", "write a poem about flowers", 50, my_stream)
end

return M
