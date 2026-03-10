--[[
    主菜单界面
--]]

local Menu = {}

-- 按钮列表
local buttons = {}

function Menu.init()
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
    love.graphics.setFont(love.graphics.newFont(24))
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
