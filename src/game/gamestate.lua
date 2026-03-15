local GameState = {}

GameState.STATE = {
    MENU = "menu",
    CARDS = "cards",
    DEPLOYMENT = "deployment",
    GAME = "game",
    PAUSE = "pause",
    GAME_OVER = "game_over",
    VICTORY = "victory",
    SETTINGS = "settings",
}

local currentState = GameState.STATE.MENU
local stateHandlers = {}

-- Global UI overlay
local settingsButtonImg = nil
local menuPopupOpen = false
local popupButtons = {}
local chineseFont = nil

local function loadChineseFont()
    if chineseFont then return end
    local fontPaths = {
        "assets/fonts/simhei.ttf",
        "assets/fonts/simkai.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/simkai.ttf",
        "C:/Windows/Fonts/msyh.ttc",
    }
    for _, path in ipairs(fontPaths) do
        local ok, font = pcall(love.graphics.newFont, path, 16)
        if ok then
            chineseFont = font
            return
        end
    end
    chineseFont = love.graphics.newFont(16)
end

local function safeLoadImage(path)
    local ok, img = pcall(love.graphics.newImage, path)
    if ok and img then
        img:setFilter("linear", "linear")
        return img
    end
    return nil
end

local function getSettingsButtonArea()
    return { x = 10, y = 10, width = 40, height = 40 }
end

local function drawSettingsButton()
    -- Don't show on menu screen
    if currentState == GameState.STATE.MENU then return end

    local area = getSettingsButtonArea()
    local mx, my = love.mouse.getPosition()
    local hovered = mx >= area.x and mx <= area.x + area.width and
                    my >= area.y and my <= area.y + area.height

    -- Button background
    if hovered then
        love.graphics.setColor(0.4, 0.5, 0.6, 0.9)
    else
        love.graphics.setColor(0.2, 0.25, 0.3, 0.85)
    end
    love.graphics.rectangle("fill", area.x, area.y, area.width, area.height, 6)
    love.graphics.setColor(0.6, 0.65, 0.7, 1)
    love.graphics.rectangle("line", area.x, area.y, area.width, area.height, 6)

    -- Settings gear icon
    love.graphics.setColor(0.9, 0.85, 0.7, 1)
    local cx = area.x + area.width / 2
    local cy = area.y + area.height / 2
    local r = 10
    -- Outer circle with notches
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", cx, cy, r)
    -- Draw gear teeth
    for i = 0, 7 do
        local angle = i * math.pi / 4
        local x1 = cx + math.cos(angle) * (r - 2)
        local y1 = cy + math.sin(angle) * (r - 2)
        local x2 = cx + math.cos(angle) * (r + 4)
        local y2 = cy + math.sin(angle) * (r + 4)
        love.graphics.line(x1, y1, x2, y2)
    end
    -- Inner circle
    love.graphics.circle("fill", cx, cy, 4)
    love.graphics.setLineWidth(1)
end

local function drawMenuPopup()
    if not menuPopupOpen then return end

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local popupWidth = 200
    local popupHeight = 120
    local popupX = 60
    local popupY = 10

    -- Popup background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 8)
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight, 8)

    popupButtons = {}

    -- Return to menu button
    local btn1Y = popupY + 15
    local btnHeight = 35
    local btnGap = 10
    local mx, my = love.mouse.getPosition()

    local btn1Hovered = mx >= popupX + 10 and mx <= popupX + popupWidth - 10 and
                        my >= btn1Y and my <= btn1Y + btnHeight
    if btn1Hovered then
        love.graphics.setColor(0.3, 0.4, 0.5, 1)
    else
        love.graphics.setColor(0.2, 0.25, 0.3, 1)
    end
    love.graphics.rectangle("fill", popupX + 10, btn1Y, popupWidth - 20, btnHeight, 5)
    love.graphics.setColor(0.6, 0.65, 0.7, 1)
    love.graphics.rectangle("line", popupX + 10, btn1Y, popupWidth - 20, btnHeight, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(chineseFont)
    local text1 = "返回主菜单"
    local tw1 = chineseFont:getWidth(text1)
    love.graphics.print(text1, popupX + (popupWidth - tw1) / 2, btn1Y + (btnHeight - 16) / 2)

    popupButtons.menu = { x = popupX + 10, y = btn1Y, width = popupWidth - 20, height = btnHeight }

    -- Exit to desktop button
    local btn2Y = btn1Y + btnHeight + btnGap
    local btn2Hovered = mx >= popupX + 10 and mx <= popupX + popupWidth - 10 and
                        my >= btn2Y and my <= btn2Y + btnHeight
    if btn2Hovered then
        love.graphics.setColor(0.4, 0.3, 0.3, 1)
    else
        love.graphics.setColor(0.25, 0.2, 0.2, 1)
    end
    love.graphics.rectangle("fill", popupX + 10, btn2Y, popupWidth - 20, btnHeight, 5)
    love.graphics.setColor(0.6, 0.5, 0.5, 1)
    love.graphics.rectangle("line", popupX + 10, btn2Y, popupWidth - 20, btnHeight, 5)
    love.graphics.setColor(1, 1, 1, 1)
    local text2 = "退出游戏"
    local tw2 = chineseFont:getWidth(text2)
    love.graphics.print(text2, popupX + (popupWidth - tw2) / 2, btn2Y + (btnHeight - 16) / 2)

    popupButtons.exit = { x = popupX + 10, y = btn2Y, width = popupWidth - 20, height = btnHeight }
end

function GameState.mousepressed(x, y, button)
    if button ~= 1 then return end

    -- Check popup buttons first if popup is open
    if menuPopupOpen then
        -- Return to menu button
        if popupButtons.menu then
            local btn = popupButtons.menu
            if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                menuPopupOpen = false
                GameState.switch("menu")
                return
            end
        end

        -- Exit button
        if popupButtons.exit then
            local btn = popupButtons.exit
            if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                love.event.quit()
                return
            end
        end

        -- Click outside popup closes it
        menuPopupOpen = false
        return
    end

    -- Check settings button (not on menu screen)
    if currentState ~= GameState.STATE.MENU then
        local area = getSettingsButtonArea()
        if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
            menuPopupOpen = true
            return
        end
    end

    -- Pass to state handler
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

function GameState.keypressed(key, scancode, isrepeat)
    -- Close popup with Escape
    if menuPopupOpen and key == "escape" then
        menuPopupOpen = false
        return
    end

    local handler = stateHandlers[currentState]
    if handler and handler.keypressed then
        handler.keypressed(key, scancode, isrepeat)
    end
end

function GameState.textinput(text)
    local handler = stateHandlers[currentState]
    if handler and handler.textinput then
        handler.textinput(text)
    end
end

function GameState.init()
    loadChineseFont()
    settingsButtonImg = safeLoadImage("assets/images/backgrounds/button1.png")

    stateHandlers[GameState.STATE.MENU] = require('src.ui.menu')
    stateHandlers[GameState.STATE.CARDS] = require('src.ui.cards')
    stateHandlers[GameState.STATE.DEPLOYMENT] = require('src.game.deployment')
    stateHandlers[GameState.STATE.GAME] = require('src.game.battle')
    stateHandlers[GameState.STATE.PAUSE] = require('src.ui.pause')
    stateHandlers[GameState.STATE.SETTINGS] = require('src.ui.settings')

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
    else
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("State: " .. currentState, 10, 10)
    end

    -- Draw global UI overlay
    drawSettingsButton()
    drawMenuPopup()
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
