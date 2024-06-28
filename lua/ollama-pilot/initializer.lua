-- purpose of this file is to maintain the co-routine that is cloning, and then building the ollama executable
M = {}
local constants = require('ollama-pilot.constants')
local job = require('plenary.job')
local util = require('ollama-pilot.util')

local INITIALIZING = "INITIALIZING"
local READY = "READY"

local status = INITIALIZING

local clone_ollama_repo_job = job:new({
    command = 'git',
    args = { 'clone', constants.OLLAMA_REPO_URL },
    cwd = constants.OLLAMA_INSTALL_DIR,
    on_start = function()
        print('cloning ollama repo')
    end,
    on_exit = function(j, return_val)
        print('finished cloning ollama')
    end,
})

local build_ollama_job = job:new({
    command = string.format('go'),
    args = { 'generate', './...' },
    cwd = constants.OLLAMA_REPO_PATH,
    on_start = function()
        print('building ollama, this will take some time...')
    end,
    on_exit = function(x, y)
        print('finished generating go sources')
        job:new({
            command = 'go',
            args = { 'build', '.' },
            cwd = constants.OLLAMA_REPO_PATH,
            on_exit = function(j, return_val)
                print('successfully built ollama')
                status = READY
            end,
        }):start()
    end,
})

local helper_coroutine = coroutine.create(function()
    local jobs = {}
    if util.is_cloned() == false then
        table.insert(jobs, clone_ollama_repo_job)
    end
    if util.is_built() == false then
        table.insert(jobs, build_ollama_job)
    end

    if #jobs == 0 then
        status = READY
    else
        job.chain(unpack(jobs))
    end
end)

M.create_executable = function()
    coroutine.resume(helper_coroutine)
end

M.get_status = function()
    return status
end


return M
