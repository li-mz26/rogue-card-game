--[[
    Settings UI
    Game settings: resolution, sound effects, volume
--]]

local Settings = {}

local chineseFont = {}
local backgroundImage = nil
local buttonImage = nil
local sliderImg = nil
local checkboxImg = nil

-- Base resolution for scaling calculations
local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080

local function getScale()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    return math.min(screenWidth / BASE_WIDTH, screenHeight / BASE_HEIGHT)
end

-- Settings data
local settingsData = {
    resolutions = {
        { w = 1280, h = 720, label = "1280 x 720" },
        { w = 1600, h = 900, label = "1600 x 900" },
        { w = 1920, h = 1080, label = "1920 x 1080" },
        { w = 2560, h = 1440, label = "2560 x 1440" },
    },
    currentResolution = 1,
    fullscreen = false,
    masterVolume = 0.8,
    musicVolume = 0.7,
    sfxVolume = 0.8,
    soundEnabled = true,
}

local clickAreas = {}
local draggingSlider = nil

local function loadChineseFonts()
    if chineseFont[16] then return true end

    local fontPaths = {
        "assets/fonts/simhei.ttf",
        "assets/fonts/simkai.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/simkai.ttf",
        "C:/Windows/Fonts/msyh.ttc",
    }

    for _, path in ipairs(fontPaths) do
        local ok = pcall(function()
            chineseFont[14] = love.graphics.newFont(path, 14)
            chineseFont[16] = love.graphics.newFont(path, 16)
            chineseFont[18] = love.graphics.newFont(path, 18)
            chineseFont[20] = love.graphics.newFont(path, 20)
            chineseFont[24] = love.graphics.newFont(path, 24)
        end)
        if ok then return true end
    end

    chineseFont[14] = love.graphics.newFont(14)
    chineseFont[16] = love.graphics.newFont(16)
    chineseFont[18] = love.graphics.newFont(18)
    chineseFont[20] = love.graphics.newFont(20)
    chineseFont[24] = love.graphics.newFont(24)
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

local function getFont(size)
    return chineseFont[size] or love.graphics.getFont()
end

local function applyResolution()
    local res = settingsData.resolutions[settingsData.currentResolution]
    if res then
        if settingsData.fullscreen then
            -- Fullscreen mode - use desktop resolution
            love.window.setMode(0, 0, { fullscreen = true, vsync = true })
        else
            -- Windowed mode
            love.window.setMode(res.w, res.h, { resizable = false, vsync = true, fullscreen = false })
        end
    end
end

local function drawSlider(x, y, width, height, value, label, scale)
    scale = scale or 1
    -- Label
    love.graphics.setColor(0.9, 0.85, 0.7)
    love.graphics.setFont(getFont(16))
    love.graphics.print(label, x, y - 25 * scale)

    -- Slider background
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", x, y, width, height, 4 * scale)

    -- Slider fill
    local fillWidth = width * value
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.rectangle("fill", x, y, fillWidth, height, 4 * scale)

    -- Slider border
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.rectangle("line", x, y, width, height, 4 * scale)

    -- Slider handle
    local handleX = x + fillWidth - 8 * scale
    love.graphics.setColor(0.9, 0.85, 0.7)
    love.graphics.rectangle("fill", handleX, y - 3 * scale, 16 * scale, height + 6 * scale, 3 * scale)
    love.graphics.setColor(0.6, 0.55, 0.45)
    love.graphics.rectangle("line", handleX, y - 3 * scale, 16 * scale, height + 6 * scale, 3 * scale)

    -- Value percentage
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setFont(getFont(14))
    love.graphics.print(string.format("%d%%", math.floor(value * 100)), x + width + 10 * scale, y)

    return { x = x, y = y, width = width, height = height }
end

local function drawCheckbox(x, y, size, checked, label, scale)
    scale = scale or 1
    -- Label
    love.graphics.setColor(0.9, 0.85, 0.7)
    love.graphics.setFont(getFont(16))
    love.graphics.print(label, x + size + 10 * scale, y + (size - 16 * scale) / 2)

    -- Checkbox background
    if checked then
        love.graphics.setColor(0.3, 0.5, 0.7)
    else
        love.graphics.setColor(0.2, 0.2, 0.25)
    end
    love.graphics.rectangle("fill", x, y, size, size, 4 * scale)

    -- Checkbox border
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.rectangle("line", x, y, size, size, 4 * scale)

    -- Checkmark
    if checked then
        love.graphics.setColor(0.9, 0.85, 0.7)
        love.graphics.setLineWidth(2 * scale)
        love.graphics.line(x + 5 * scale, y + size / 2, x + size / 2, y + size - 5 * scale)
        love.graphics.line(x + size / 2, y + size - 5 * scale, x + size - 5 * scale, y + 5 * scale)
        love.graphics.setLineWidth(1)
    end

    return { x = x, y = y, width = size, height = size }
end

local function drawResolutionSelector(x, y, width, height, currentIndex, options, label, scale)
    scale = scale or 1
    -- Label
    love.graphics.setColor(0.9, 0.85, 0.7)
    love.graphics.setFont(getFont(16))
    love.graphics.print(label, x, y - 25 * scale)

    local btnWidth = (width - 20 * scale) / 2
    local currentValue = options[currentIndex] and options[currentIndex].label or "Unknown"

    -- Current value display
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", x, y, width, height, 4 * scale)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.rectangle("line", x, y, width, height, 4 * scale)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(getFont(16))
    local textWidth = getFont(16):getWidth(currentValue)
    love.graphics.print(currentValue, x + (width - textWidth) / 2, y + (height - 16 * scale) / 2)

    -- Left arrow
    local leftBtnX = x - btnWidth - 10 * scale
    love.graphics.setColor(0.25, 0.25, 0.3)
    love.graphics.rectangle("fill", leftBtnX, y, btnWidth, height, 4 * scale)
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.rectangle("line", leftBtnX, y, btnWidth, height, 4 * scale)
    love.graphics.setColor(0.9, 0.85, 0.7)
    love.graphics.setFont(getFont(20))
    love.graphics.print("<", leftBtnX + btnWidth / 2 - 6 * scale, y + (height - 20 * scale) / 2)

    -- Right arrow
    local rightBtnX = x + width + 10 * scale
    love.graphics.setColor(0.25, 0.25, 0.3)
    love.graphics.rectangle("fill", rightBtnX, y, btnWidth, height, 4 * scale)
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.rectangle("line", rightBtnX, y, btnWidth, height, 4 * scale)
    love.graphics.setColor(0.9, 0.85, 0.7)
    love.graphics.setFont(getFont(20))
    love.graphics.print(">", rightBtnX + btnWidth / 2 - 6 * scale, y + (height - 20 * scale) / 2)

    return {
        leftBtn = { x = leftBtnX, y = y, width = btnWidth, height = height },
        rightBtn = { x = rightBtnX, y = y, width = btnWidth, height = height }
    }
end

local function drawButton(x, y, width, height, text, img, scale)
    scale = scale or 1
    local mx, my = love.mouse.getPosition()
    local hovered = mx >= x and mx <= x + width and my >= y and my <= y + height

    if img then
        local imgScale = math.min(width / img:getWidth(), height / img:getHeight())
        local drawW = img:getWidth() * imgScale
        local drawH = img:getHeight() * imgScale
        local drawX = x + (width - drawW) / 2
        local drawY = y + (height - drawH) / 2
        love.graphics.setColor(1, 1, 1, hovered and 1 or 0.85)
        love.graphics.draw(img, drawX, drawY, 0, imgScale, imgScale)
    else
        if hovered then
            love.graphics.setColor(0.35, 0.5, 0.7)
        else
            love.graphics.setColor(0.25, 0.35, 0.45)
        end
        love.graphics.rectangle("fill", x, y, width, height, 5 * scale)
        love.graphics.setColor(0.6, 0.7, 0.8)
        love.graphics.rectangle("line", x, y, width, height, 5 * scale)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(getFont(16))
    local tw = getFont(16):getWidth(text)
    love.graphics.print(text, x + (width - tw) / 2, y + (height - 16 * scale) / 2)

    return { x = x, y = y, width = width, height = height, hovered = hovered }
end

function Settings.init()
    loadChineseFonts()

    backgroundImage = safeLoadImage("assets/images/backgrounds/bg_menu.png")
    buttonImage = safeLoadImage("assets/images/backgrounds/button1.png")

    clickAreas = {}
    draggingSlider = nil
end

function Settings.update(dt)
    -- Handle slider dragging
    if draggingSlider and love.mouse.isDown(1) then
        local mx = love.mouse.getX()
        local slider = draggingSlider
        local newValue = (mx - slider.x) / slider.width
        newValue = math.max(0, math.min(1, newValue))

        if slider.type == "master" then
            settingsData.masterVolume = newValue
        elseif slider.type == "music" then
            settingsData.musicVolume = newValue
        elseif slider.type == "sfx" then
            settingsData.sfxVolume = newValue
        end
    else
        draggingSlider = nil
    end
end

function Settings.draw()
    clickAreas = {}

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local scale = getScale()

    -- Draw background
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

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Title
    love.graphics.setColor(0.95, 0.85, 0.5)
    love.graphics.setFont(getFont(24))
    local titleText = "游戏设置"
    local titleWidth = getFont(24):getWidth(titleText)
    love.graphics.print(titleText, screenWidth / 2 - titleWidth / 2, 60 * scale)

    -- Settings panel
    local panelWidth = 500 * scale
    local panelX = (screenWidth - panelWidth) / 2
    local panelY = 110 * scale
    local panelHeight = screenHeight - 220 * scale

    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 8 * scale)
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 8 * scale)

    local contentX = panelX + 40 * scale
    local sliderWidth = panelWidth - 100 * scale
    local itemY = panelY + 40 * scale
    local itemGap = 70 * scale

    -- Resolution selector
    local resAreas = drawResolutionSelector(
        contentX + 50 * scale, itemY, 200 * scale, 36 * scale,
        settingsData.currentResolution,
        settingsData.resolutions,
        "分辨率",
        scale
    )
    clickAreas.resolutionLeft = resAreas.leftBtn
    clickAreas.resolutionRight = resAreas.rightBtn
    itemY = itemY + itemGap

    -- Fullscreen checkbox
    clickAreas.fullscreen = drawCheckbox(
        contentX, itemY, 28 * scale,
        settingsData.fullscreen,
        "全屏模式",
        scale
    )
    itemY = itemY + itemGap + 20 * scale

    -- Sound enable checkbox
    clickAreas.soundEnabled = drawCheckbox(
        contentX, itemY, 28 * scale,
        settingsData.soundEnabled,
        "音效开关",
        scale
    )
    itemY = itemY + itemGap

    -- Master volume slider
    if settingsData.soundEnabled then
        local masterSlider = drawSlider(
            contentX, itemY, sliderWidth, 16 * scale,
            settingsData.masterVolume,
            "主音量",
            scale
        )
        masterSlider.type = "master"
        clickAreas.masterVolume = masterSlider
        itemY = itemY + itemGap

        -- Music volume slider
        local musicSlider = drawSlider(
            contentX, itemY, sliderWidth, 16 * scale,
            settingsData.musicVolume,
            "音乐音量",
            scale
        )
        musicSlider.type = "music"
        clickAreas.musicVolume = musicSlider
        itemY = itemY + itemGap

        -- SFX volume slider
        local sfxSlider = drawSlider(
            contentX, itemY, sliderWidth, 16 * scale,
            settingsData.sfxVolume,
            "音效音量",
            scale
        )
        sfxSlider.type = "sfx"
        clickAreas.sfxVolume = sfxSlider
        itemY = itemY + itemGap
    end

    -- Buttons at bottom
    local btnY = panelY + panelHeight - 60 * scale
    local btnWidth = 120 * scale
    local btnHeight = 40 * scale
    local btnGap = 20 * scale

    -- Apply button
    clickAreas.apply = drawButton(
        screenWidth / 2 - btnWidth - btnGap / 2 - 70 * scale, btnY,
        btnWidth, btnHeight, "应用", buttonImage, scale
    )

    -- Back button
    clickAreas.back = drawButton(
        screenWidth / 2 - btnWidth / 2 + 70 * scale, btnY,
        btnWidth, btnHeight, "返回", buttonImage, scale
    )
end

function Settings.mousepressed(x, y, button)
    if button ~= 1 then return end

    -- Resolution left arrow
    if clickAreas.resolutionLeft then
        local area = clickAreas.resolutionLeft
        if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
            settingsData.currentResolution = settingsData.currentResolution - 1
            if settingsData.currentResolution < 1 then
                settingsData.currentResolution = #settingsData.resolutions
            end
            return
        end
    end

    -- Resolution right arrow
    if clickAreas.resolutionRight then
        local area = clickAreas.resolutionRight
        if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
            settingsData.currentResolution = settingsData.currentResolution + 1
            if settingsData.currentResolution > #settingsData.resolutions then
                settingsData.currentResolution = 1
            end
            return
        end
    end

    -- Fullscreen checkbox
    if clickAreas.fullscreen then
        local area = clickAreas.fullscreen
        if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
            settingsData.fullscreen = not settingsData.fullscreen
            return
        end
    end

    -- Sound enable checkbox
    if clickAreas.soundEnabled then
        local area = clickAreas.soundEnabled
        if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
            settingsData.soundEnabled = not settingsData.soundEnabled
            return
        end
    end

    -- Volume sliders
    for _, key in ipairs({"masterVolume", "musicVolume", "sfxVolume"}) do
        local area = clickAreas[key]
        if area then
            if x >= area.x and x <= area.x + area.width and y >= area.y - 5 and y <= area.y + area.height + 5 then
                draggingSlider = area
                -- Update value immediately on click
                local newValue = (x - area.x) / area.width
                newValue = math.max(0, math.min(1, newValue))
                if key == "masterVolume" then
                    settingsData.masterVolume = newValue
                elseif key == "musicVolume" then
                    settingsData.musicVolume = newValue
                elseif key == "sfxVolume" then
                    settingsData.sfxVolume = newValue
                end
                return
            end
        end
    end

    -- Apply button
    if clickAreas.apply then
        local area = clickAreas.apply
        if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
            applyResolution()
            return
        end
    end

    -- Back button
    if clickAreas.back then
        local area = clickAreas.back
        if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
            local GameState = require('src.game.gamestate')
            GameState.switch("menu")
            return
        end
    end
end

function Settings.exit()
end

-- Get current settings (for use by other modules)
function Settings.getVolume()
    if not settingsData.soundEnabled then
        return 0, 0, 0
    end
    return settingsData.masterVolume, settingsData.musicVolume, settingsData.sfxVolume
end

function Settings.isSoundEnabled()
    return settingsData.soundEnabled
end

return Settings