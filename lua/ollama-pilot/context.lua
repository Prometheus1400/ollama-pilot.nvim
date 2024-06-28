-- This context is passed into requests, they are expected to register any callbacks (cleanup logic) to cancel the request

local Context = {}
Context.__index = Context

function Context:new()
    local instance = {
        callbacks = {},
    }
    setmetatable(instance, Context)
    return instance
end

function Context:send_cancel()
    for _, callback in ipairs(self.callbacks) do
        callback()
    end
end

function Context:register_callback_on_cancel(callback)
    table.insert(self.callbacks, callback)
end

return Context
