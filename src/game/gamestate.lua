local GameState = {}

GameState.STATE = {
    MENU = "menu",
    CARDS = "cards",
    DEPLOYMENT = "deployment",
    GAME = "game",
    PAUSE = "pause",
    GAME_OVER = "game_over",
    VICTORY = "victory",
}

local currentState = GameState.STATE.MENU
local stateHandlers = {}

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

function GameState.wheelmoved(x, y)
    local handler = stateHandlers[currentState]
    if handler and handler.wheelmoved then
        handler.wheelmoved(x, y)
    end
end

function GameState.init()
    stateHandlers[GameState.STATE.MENU] = require('src.ui.menu')
    stateHandlers[GameState.STATE.CARDS] = require('src.ui.cards')
    stateHandlers[GameState.STATE.DEPLOYMENT] = require('src.game.deployment')
    stateHandlers[GameState.STATE.GAME] = require('src.game.battle')
    stateHandlers[GameState.STATE.PAUSE] = require('src.ui.pause')

    local handler = stateHandlers[currentState]
    if handler and handler.init then
        handler.init()
    end
end

function GameState.update(dt)
    local handler = stateHandlers[currentState]
    if handler and handler.update then
        handler.update(dt)
    end
end

function GameState.draw()
    local handler = stateHandlers[currentState]
    if handler and handler.draw then
        handler.draw()
        return
    end

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("State: " .. currentState, 10, 10)
end

function GameState.switch(state)
    local stateUpper = string.upper(state)
    local nextState = GameState.STATE[stateUpper]
    if not nextState then
        error("Unknown state: " .. tostring(state))
    end

    local currentHandler = stateHandlers[currentState]
    if currentHandler and currentHandler.exit then
        currentHandler.exit()
    end

    currentState = nextState

    local nextHandler = stateHandlers[currentState]
    if nextHandler and nextHandler.init then
        nextHandler.init()
    end

    print("Switched state to: " .. currentState)
end

function GameState.getCurrentState()
    return currentState
end

return GameState
