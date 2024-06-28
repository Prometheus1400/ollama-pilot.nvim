local Stream = {}
Stream.__index = Stream

function Stream:new(callback)
    local instance = {
        buffer = {},
        callback = callback
    }
    setmetatable(instance, Stream)
    return instance
end

function Stream:write(data)
    table.insert(self.buffer, data)
    self.callback(data)
end

return Stream
