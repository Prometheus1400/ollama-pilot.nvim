local M = {}

---@class ollama.config
---@field model string
---@field token_delay number
---@field ollama_port string
---@field ollama_path string?
---@field ollama_lazy_startup boolean
---@field popup table
---@field autocomplete table

--- Ollama global resolved configuration
---
---@type ollama.config?
M.config = nil

--- Ollama default configuration
---
---@type ollama.config
M.default_config = {
    model = "llama3",
    token_delay = 50,
    ollama_port = "11434",
    ollama_path = nil,
    ollama_lazy_startup = false,
    popup = {
        relative = 'cursor',
        row = 1,
        col = 0,
        width = 120,
        height = 20,
        style = 'minimal',
    },
    chat = {
    },
    autocomplete = {
        -- how many lines to grab above AND below the current position to add as context to autocomplete request
        context_line_size = 100,
    }
}

---@param defaults ollama.config
---@param settings ollama.config
---@return ollama.config
local function merge(defaults, settings)
    settings = settings or {}
    for k, v in pairs(defaults) do
        if type(v) == "table" and type(settings[k]) == "table" then
            settings[k] = merge(v, settings[k])
        elseif settings[k] == nil then
            settings[k] = v
        end
    end
    return settings
end

M.set_config = function(opts)
    M.config = merge(M.default_config, opts)
end

M.get_config = function()
    return M.config
end


return M
