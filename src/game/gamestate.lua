--[[
    游戏状态管理器
--]]

local GameState = {}

-- 游戏状态枚举
GameState.STATE = {
    MENU = "menu",
    DEPLOYMENT = "deployment",  -- 布阵阶段
    GAME = "game",
    PAUSE = "pause",
    GAME_OVER = "game_over",
    VICTORY = "victory"
}

-- 当前状态
local currentState = GameState.STATE.MENU

-- 状态处理器
local stateHandlers = {}

-- 输入事件转发
function GameState.mousepressed(x, y, button)
    local handler = stateHandlers[currentState]
    if handler and handler.mousepressed then
        handler.mousepressed(x, y, button)
    end
end

function GameState.mousereleased(x, y, button)
    local handler = stateHandlers[currentState]
    if handler and handler.mousereleased then
        handler.mousereleased(x, y, button)
    end
end

function GameState.mousemoved(x, y, dx, dy)
    local handler = stateHandlers[currentState]
    if handler and handler.mousemoved then
        handler.mousemoved(x, y, dx, dy)
    end
end

function GameState.init()
    -- 初始化各个状态处理器
    stateHandlers[GameState.STATE.MENU] = require('src.ui.menu')
    stateHandlers[GameState.STATE.DEPLOYMENT] = require('src.game.deployment')
    stateHandlers[GameState.STATE.GAME] = require('src.game.battle')
    stateHandlers[GameState.STATE.PAUSE] = require('src.ui.pause')
    
    -- 初始化当前状态
    if stateHandlers[currentState] and stateHandlers[currentState].init then
        stateHandlers[currentState].init()
    end
end

function GameState.update(dt)
    if stateHandlers[currentState] and stateHandlers[currentState].update then
        stateHandlers[currentState].update(dt)
    end
end

function GameState.draw()
    if stateHandlers[currentState] and stateHandlers[currentState].draw then
        stateHandlers[currentState].draw()
    else
        -- 默认绘制
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("State: " .. currentState, 10, 10)
    end
end

function GameState.switch(state)
    if GameState.STATE[state:upper()] then
        -- 退出当前状态
        if stateHandlers[currentState] and stateHandlers[currentState].exit then
            stateHandlers[currentState].exit()
        end
        
        currentState = state
        
        -- 进入新状态
        if stateHandlers[currentState] and stateHandlers[currentState].init then
            stateHandlers[currentState].init()
        end
        
        print("切换到状态: " .. state)
    else
        error("未知状态: " .. state)
    end
end

function GameState.getCurrentState()
    return currentState
end

return GameState
