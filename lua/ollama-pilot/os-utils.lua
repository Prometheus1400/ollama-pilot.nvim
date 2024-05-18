M = {}

os = require('os')
io = require('io')
local job = require('plenary.job')
local constants = require('ollama-pilot.constants')

local noop_job = job:new({
    command = 'echo',
})


M.get_start_ollama_job = function(repo_dir)
    return job:new({
        command = string.format('%s', repo_dir .. '/' .. constants.OLLAMA),
        args = { 'serve' },
        skip_validation = true,
        -- cwd = plugin_dir,
        on_start = function()
            print('starting ollama server')
        end,
        on_exit = function(x, y)
            print('stopping ollama server')
        end
    })
end

M.get_build_ollama_job = function(repo_dir)
    local ollama_exe_path = repo_dir .. '/' .. constants.OLLAMA
    print(ollama_exe_path)
    local exe_file = io.open(ollama_exe_path, 'r')
    print(exe_file)
    if not exe_file then
        print('returning build job')
        return job:new({
            command = string.format('go'),
            args = { 'generate', './...' },
            cwd = repo_dir,
            on_start = function()
                print('building ollama, this will take some time...')
            end,
            on_exit = function(x, y)
                print('finished generating go sources')
                job:new({
                    command = 'go',
                    args = { 'build', '.' },
                    cwd = repo_dir,
                    on_start = function()
                        print('building...')
                    end,
                    on_exit = function(j, return_val)
                        print('successfully built ollama')
                        -- os.execute(string.format('rm -r %s', repo_dir))
                    end,
                }):start()
            end,
        })
    else
        return noop_job
    end
end

M.get_clone_ollama_repo_job = function(install_path)
    local ollama_path = install_path .. '/' .. constants.OLLAMA
    local repo_dir = io.open(ollama_path, 'r')
    print(repo_dir, ollama_path)
    if not repo_dir then
        print('returning clone job')
        return job:new({
            command = 'git',
            args = { 'clone', constants.OLLAMA_REPO_URL },
            cwd = install_path,
            on_start = function()
                print('cloning ollama repo')
            end,
            on_exit = function(j, return_val)
                print('finished cloning ollama')
            end,
        })
    else
        return noop_job
    end
end

return M
