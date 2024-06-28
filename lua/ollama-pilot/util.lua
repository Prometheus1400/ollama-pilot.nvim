M = {}
local constants = require('ollama-pilot.constants')

M.is_cloned = function()
    local repo_dir = io.open(constants.OLLAMA_REPO_PATH, 'r')
    if not repo_dir then
        return false
    else
        repo_dir:close()
        return true
    end
end

M.is_built = function()
    local exe_file = io.open(constants.OLLAMA_EXE_PATH, 'r')
    if not exe_file then
        return false
    else
        exe_file:close()
        return true
    end
end

return M
