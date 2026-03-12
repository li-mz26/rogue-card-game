--[[
    简单的事件系统
--]]

local Event = {}

-- 事件监听�?
local listeners = {}

function Event.on(eventName, callback)
    if not listeners[eventName] then
        listeners[eventName] = {}
    end
    table.insert(listeners[eventName], callback)
end

function Event.off(eventName, callback)
    if not listeners[eventName] then
        return
    end
    
    for i, listener in ipairs(listeners[eventName]) do
        if listener == callback then
            table.remove(listeners[eventName], i)
            break
        end
    end
end

function Event.trigger(eventName, ...)
    if not listeners[eventName] then
        return
    end
    
    for _, callback in ipairs(listeners[eventName]) do
        callback(...)
    end
end

function Event.clear(eventName)
    if eventName then
        listeners[eventName] = nil
    else
        listeners = {}
    end
end

return Event
