--[[
    Main menu UI
--]]

local Menu = {}

local buttons = {}
local chineseFont = nil
local chineseFontSmall = nil

local function loadChineseFonts()
    local fontPaths = {
        "assets/fonts/simhei.ttf",
        "assets/fonts/simkai.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/simkai.ttf",
        "C:/Windows/Fonts/simsun.ttc",
    }

    for _, path in ipairs(fontPaths) do
        local success, font = pcall(function()
            return love.graphics.newFont(path, 24)
        end)
        if success then
            chineseFont = font
            local success2, smallFont = pcall(function()
                return love.graphics.newFont(path, 18)
            end)
            if success2 then
                chineseFontSmall = smallFont
            end
            print("Loaded font: " .. path)
            return true
        end
    end

    chineseFont = love.graphics.newFont(24)
    chineseFontSmall = love.graphics.newFont(18)
    print("Warning: Chinese font not found")
    return false
end

function Menu.init()
    if not chineseFont then
        loadChineseFonts()
    end

    buttons = {}

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local centerX = screenWidth / 2
    local startY = screenHeight / 2 - 50

    table.insert(buttons, {
        text = "Start Game",
        x = centerX - 100,
        y = startY,
        width = 200,
        height = 50,
        onClick = function()
            local GameState = require('src.game.gamestate')
            GameState.switch("deployment")
        end
    })

    table.insert(buttons, {
        text = "Card Collection",
        x = centerX - 100,
        y = startY + 70,
        width = 200,
        height = 50,
        onClick = function()
            local GameState = require('src.game.gamestate')
            GameState.switch("cards")
        end
    })

    table.insert(buttons, {
        text = "Quit",
        x = centerX - 100,
        y = startY + 140,
        width = 200,
        height = 50,
        onClick = function()
            love.event.quit()
        end
    })
end

function Menu.update(dt)
    local mx, my = love.mouse.getPosition()
    for _, btn in ipairs(buttons) do
        btn.hovered = mx >= btn.x and mx <= btn.x + btn.width
            and my >= btn.y and my <= btn.y + btn.height
    end
end

function Menu.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    love.graphics.setColor(0.9, 0.8, 0.4)
    local title = "Rogue Card Game"
    local titleFont = love.graphics.newFont(48)
    love.graphics.setFont(titleFont)
    local titleWidth = titleFont:getWidth(title)
    love.graphics.print(title, (screenWidth - titleWidth) / 2, 150)

    love.graphics.setFont(chineseFont or love.graphics.newFont(24))
    for _, btn in ipairs(buttons) do
        if btn.hovered then
            love.graphics.setColor(0.3, 0.5, 0.7)
        else
            love.graphics.setColor(0.2, 0.3, 0.4)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5, 5)

        love.graphics.setColor(0.5, 0.6, 0.7)
        love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5, 5)

        love.graphics.setColor(1, 1, 1)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(btn.text)
        local textHeight = font:getHeight()
        love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2,
            btn.y + (btn.height - textHeight) / 2)
    end

    love.graphics.setColor(1, 1, 1)
end

function Menu.mousepressed(x, y, button)
    if button ~= 1 then return end

    for _, btn in ipairs(buttons) do
        if btn.hovered and btn.onClick then
            btn.onClick()
            break
        end
    end
end

function Menu.exit()
end

return Menu
