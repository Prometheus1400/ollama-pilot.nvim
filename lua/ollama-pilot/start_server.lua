M = {}
local constants = require('ollama-pilot.constants')
local job = require('plenary.job')

local start_ollama = function(ollama_repo_dir)
    print('starting up ollama server...')
    job:new({
        command = string.format('./%', ollama_repo_dir .. constants.OLLAMA),
        cwd = ollama_repo_dir,
        on_exit = function(j, return_val)
        end,
    }):start()
end


return M
