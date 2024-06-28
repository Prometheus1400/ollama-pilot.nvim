M = {}
local constants = require('ollama-pilot.constants')
local util = require('ollama-pilot.util')
local log = require("ollama-pilot.log")
local uv = vim.loop

local handle = nil
local active = false

M.start = function()
    assert(util.is_built(), 'no executable to run')
    if handle ~= nil and handle:is_active() then
        print("Ollama is already running!")
        return
    end
    print("Starting Ollama")
    active = true
    local log_pipe = log:get_pipe()

    local onExit = function(code, signal)
        if code ~= 0 then
            print("Error during Ollama execution! Status: " .. code .. " Signal: " .. signal)
            return
        end
        print("Ollama stopped successfully")
        if handle ~= nil then
            handle:close()
            handle = nil
            log_pipe:close()
        end
    end

    handle, _ = uv.spawn(constants.OLLAMA_EXE_PATH, {
        args = { 'serve' },
        stdio = { nil, log_pipe, nil }
    }, onExit)
end

M.stop = function()
    if handle == nil or not handle:is_active() then
        return
    else
        handle:kill()
    end
end

M.restart = function()
    M.stop()
    M.start()
end

M.is_active = function()
    return active
end

return M
