M = {}

local constants = require("ollama-pilot.constants")
local uv = vim.loop

local log_pipe = nil

M.get_pipe = function()
    if log_pipe == nil or not log_pipe:is_active() then
        local fd = uv.fs_open(constants.OLLAMA_LOG_PATH, "a", 438)
        assert(fd ~= nil, "could not open ollama log file (" .. constants.OLLAMA_LOG_PATH .. ")")
        log_pipe = uv.new_pipe(true)
        uv.pipe_open(log_pipe, fd)
    end
    return log_pipe
end

return M
