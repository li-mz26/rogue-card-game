--[[
    输入管理器
--]]

local Input = {}

-- 按键绑定
local keyBindings = {}

-- 鼠标位置
local mouseX, mouseY = 0, 0
local mouseDown = false

function Input.bind(key, action)
    keyBindings[key] = action
end

function Input.unbind(key)
    keyBindings[key] = nil
end

function Input.keypressed(key)
    local action = keyBindings[key]
    if action then
        action()
    end
    
    -- 全局按键处理
    if key == "escape" then
        local GameState = require('src.game.gamestate')
        if GameState.getCurrentState() == GameState.STATE.GAME then
            GameState.switch("pause")
        elseif GameState.getCurrentState() == GameState.STATE.PAUSE then
            GameState.switch("game")
        end
    end
end

function Input.mousepressed(x, y, button)
    mouseDown = true
    mouseX, mouseY = x, y
    
    -- 广播鼠标按下事件
    local Event = require('src.utils.event')
    Event.trigger("mousepressed", x, y, button)
end

function Input.mousereleased(x, y, button)
    mouseDown = false
    
    -- 广播鼠标释放事件
    local Event = require('src.utils.event')
    Event.trigger("mousereleased", x, y, button)
end

function Input.mousemoved(x, y, dx, dy)
    mouseX, mouseY = x, y
    
    -- 广播鼠标移动事件
    local Event = require('src.utils.event')
    Event.trigger("mousemoved", x, y, dx, dy)
end

function Input.getMousePosition()
    return mouseX, mouseY
end

function Input.isMouseDown()
    return mouseDown
end

return Input
