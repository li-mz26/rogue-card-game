--[[
    Main menu UI
--]]

local Menu = {}

local buttons = {}
local chineseFont = nil
local chineseFontSmall = nil
local backgroundImage = nil
local titleImage = nil
local buttonImage = nil

local function loadChineseFonts()
    local fontPaths = {
        "assets/fonts/feibo.otf",
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

local function safeLoadImage(path)
    local ok, img = pcall(love.graphics.newImage, path)
    if ok and img then
        img:setFilter("linear", "linear")
        return img
    end
    return nil
end

-- Base resolution for scaling calculations
local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080

local function getScale()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    return math.min(screenWidth / BASE_WIDTH, screenHeight / BASE_HEIGHT)
end

function Menu.init()
    if not chineseFont then
        loadChineseFonts()
    end

    -- Load images
    backgroundImage = safeLoadImage("assets/images/backgrounds/bg_menu.png")
    titleImage = safeLoadImage("assets/images/backgrounds/title.png")
    buttonImage = safeLoadImage("assets/images/backgrounds/button.png")

    buttons = {}
    Menu.recalculateLayout()
end

function Menu.recalculateLayout()
    buttons = {}

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local centerX = screenWidth / 2
    local scale = getScale()

    -- Button dimensions scaled by resolution
    local baseButtonW = 180
    local baseButtonH = 50
    local buttonW = baseButtonW * scale
    local buttonH = baseButtonH * scale
    local gap = 15 * scale
    local startY = screenHeight / 2 + 50 * scale

    table.insert(buttons, {
        text = "开始游戏",
        x = centerX - buttonW / 2,
        y = startY,
        width = buttonW,
        height = buttonH,
        onClick = function()
            local GameState = require('src.game.gamestate')
            GameState.switch("deployment")
        end
    })

    table.insert(buttons, {
        text = "卡牌收藏",
        x = centerX - buttonW / 2,
        y = startY + buttonH + gap,
        width = buttonW,
        height = buttonH,
        onClick = function()
            local GameState = require('src.game.gamestate')
            GameState.switch("cards")
        end
    })

    table.insert(buttons, {
        text = "游戏设置",
        x = centerX - buttonW / 2,
        y = startY + (buttonH + gap) * 2,
        width = buttonW,
        height = buttonH,
        onClick = function()
            local GameState = require('src.game.gamestate')
            GameState.switch("settings")
        end
    })

    table.insert(buttons, {
        text = "退出游戏",
        x = centerX - buttonW / 2,
        y = startY + (buttonH + gap) * 3,
        width = buttonW,
        height = buttonH,
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
    local scale = getScale()

    -- Draw background image
    if backgroundImage then
        love.graphics.setColor(1, 1, 1, 1)
        local bgScale = math.max(screenWidth / backgroundImage:getWidth(), screenHeight / backgroundImage:getHeight())
        local drawW = backgroundImage:getWidth() * bgScale
        local drawH = backgroundImage:getHeight() * bgScale
        local offsetX = (drawW - screenWidth) / 2
        local offsetY = (drawH - screenHeight) / 2
        love.graphics.draw(backgroundImage, -offsetX, -offsetY, 0, bgScale, bgScale)
    else
        love.graphics.setColor(0.1, 0.1, 0.15)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    end

    -- Draw title image
    if titleImage then
        love.graphics.setColor(1, 1, 1, 1)
        local titleScale = 0.4 * scale
        local titleW = titleImage:getWidth() * titleScale
        local titleH = titleImage:getHeight() * titleScale
        love.graphics.draw(titleImage, (screenWidth - titleW) / 2, 20 * scale, 0, titleScale, titleScale)
    end

    -- Draw buttons
    love.graphics.setFont(chineseFont or love.graphics.newFont(24))
    for _, btn in ipairs(buttons) do
        -- Button lift effect on hover
        local liftOffset = btn.hovered and -4 * scale or 0
        local drawY = btn.y + liftOffset

        if buttonImage then
            -- Draw button image
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(buttonImage, btn.x, drawY, 0, btn.width / buttonImage:getWidth(), btn.height / buttonImage:getHeight())
        else
            -- Fallback: drawn button
            if btn.hovered then
                love.graphics.setColor(0.3, 0.5, 0.7)
            else
                love.graphics.setColor(0.2, 0.3, 0.4)
            end
            love.graphics.rectangle("fill", btn.x, drawY, btn.width, btn.height, 5 * scale, 5 * scale)
            love.graphics.setColor(0.5, 0.6, 0.7)
            love.graphics.rectangle("line", btn.x, drawY, btn.width, btn.height, 5 * scale, 5 * scale)
        end

        -- Draw button text (black color)
        love.graphics.setColor(0, 0, 0)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(btn.text)
        local textHeight = font:getHeight()
        love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2,
            drawY + (btn.height - textHeight) / 2)
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