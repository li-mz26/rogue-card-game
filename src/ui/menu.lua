--[[
    主菜单界面
--]]

local Menu = {}

-- 按钮列表
local buttons = {}

-- 中文字体
local chineseFont = nil
local chineseFontSmall = nil

-- 加载中文字体
local function loadChineseFonts()
    -- 优先加载项目内的字体，然后尝试系统字体
    local fontPaths = {
        "assets/fonts/simhei.ttf",        -- 项目内黑体 (推荐)
        "assets/fonts/simkai.ttf",        -- 项目内楷体
        "C:/Windows/Fonts/simhei.ttf",    -- 系统黑体
        "C:/Windows/Fonts/simkai.ttf",    -- 系统楷体
        "C:/Windows/Fonts/simsun.ttc",    -- 系统宋体
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
            print("成功加载字体: " .. path)
            return true
        end
    end
    
    -- 如果都失败，使用默认字体（中文会显示为方框）
    chineseFont = love.graphics.newFont(24)
    chineseFontSmall = love.graphics.newFont(18)
    print("警告: 未找到中文字体，中文可能显示为方框")
    return false
end

function Menu.init()
    -- 加载字体
    if not chineseFont then
        loadChineseFonts()
    end
    
    buttons = {}
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local centerX = screenWidth / 2
    local startY = screenHeight / 2 - 50
    
    -- 开始游戏按钮
    table.insert(buttons, {
        text = "开始游戏",
        x = centerX - 100,
        y = startY,
        width = 200,
        height = 50,
        onClick = function()
            local GameState = require('src.game.gamestate')
            GameState.switch("game")
        end
    })
    
    -- 退出按钮
    table.insert(buttons, {
        text = "退出",
        x = centerX - 100,
        y = startY + 70,
        width = 200,
        height = 50,
        onClick = function()
            love.event.quit()
        end
    })
end

function Menu.update(dt)
    -- 检查鼠标悬停
    local mx, my = love.mouse.getPosition()
    for _, btn in ipairs(buttons) do
        btn.hovered = mx >= btn.x and mx <= btn.x + btn.width
                      and my >= btn.y and my <= btn.y + btn.height
    end
end

function Menu.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- 背景
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- 标题
    love.graphics.setColor(0.9, 0.8, 0.4)
    local title = "Rogue Card Game"
    local titleFont = love.graphics.newFont(48)
    love.graphics.setFont(titleFont)
    local titleWidth = titleFont:getWidth(title)
    love.graphics.print(title, (screenWidth - titleWidth) / 2, 150)
    
    -- 按钮
    love.graphics.setFont(chineseFont or love.graphics.newFont(24))
    for _, btn in ipairs(buttons) do
        -- 按钮背景
        if btn.hovered then
            love.graphics.setColor(0.3, 0.5, 0.7)
        else
            love.graphics.setColor(0.2, 0.3, 0.4)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5, 5)
        
        -- 按钮边框
        love.graphics.setColor(0.5, 0.6, 0.7)
        love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5, 5)
        
        -- 按钮文字
        love.graphics.setColor(1, 1, 1)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(btn.text)
        local textHeight = font:getHeight()
        love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2, 
                           btn.y + (btn.height - textHeight) / 2)
    end
    
    -- 重置颜色
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
    -- 清理资源
end

return Menu
