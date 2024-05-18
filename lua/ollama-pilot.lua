M = {}
local os_utils = require('ollama-pilot.os-utils')
local constants = require('ollama-pilot.constants')
local job = require('plenary.job')


M.setup = function(opts)
    local cwd = vim.fn.getcwd()
    local ollama_install_path = constants.OLLAMA_INSTALL_DIR
    local ollama_repo_path = ollama_install_path .. '/' .. constants.OLLAMA
    local clone_job = os_utils.get_clone_ollama_repo_job(ollama_install_path)
    local build_job = os_utils.get_build_ollama_job(ollama_repo_path)
    local start_job = os_utils.get_start_ollama_job(ollama_repo_path)

    job.chain(clone_job, build_job, start_job)
end


return M
