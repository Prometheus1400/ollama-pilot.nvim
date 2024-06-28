M = {}

local initializer = require('ollama-pilot.initializer')
local ollama = require('ollama-pilot.ollama')
local config = require "ollama-pilot.config"
local api = require("ollama-pilot.api")

local register_commands = function()
    vim.api.nvim_create_user_command('OllamaStart', function()
        ollama.start()
    end, {})
    vim.api.nvim_create_user_command('OllamaStop', function()
        ollama.stop()
    end, {})
end

local register_default_keybinds = function()
    vim.keymap.set("v", "<leader>oe", api.explain_selection)
end

local register_autocommands = function()
    vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
        group = vim.api.nvim_create_augroup('StopOllama', { clear = true }),
        callback = function()
            ollama.stop()
        end
    })
    vim.api.nvim_create_autocmd("CursorHoldI", {
        group = vim.api.nvim_create_augroup('OllamaAutocomplete', { clear = true }),
        callback = api.autocomplete_suggestion,
    })
end


M.setup = function(options)
    config.set_config(options)

    local cfg = config.get_config()

    if cfg.ollama_path == nil then
        -- coroutine that creates ollama executable if not already built
        -- require gcc, cmake, and go to be installed on system
        initializer.create_executable()
    end

    if not cfg.ollama_lazy_startup then
        ollama.start()
    end

    -- TODO see if this is necessary
    register_commands()
    register_default_keybinds()
    register_autocommands()
end

return M
