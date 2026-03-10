--[[
    Rogue Card Game
    一个使用 LÖVE2D 开发的 Roguelike 卡牌游戏
--]]

-- 导入模块
local GameState = require('src.game.gamestate')
local Input = require('src.utils.input')

function love.load()
    love.window.setTitle("Rogue Card Game")
    
    -- 初始化随机种子
    math.randomseed(os.time())
    
    -- 初始化游戏状态
    GameState.init()
    
    print("游戏加载完成!")
end

function love.update(dt)
    GameState.update(dt)
end

function love.draw()
    GameState.draw()
end

function love.keypressed(key)
    Input.keypressed(key)
end

function love.mousepressed(x, y, button)
    Input.mousepressed(x, y, button)
    GameState.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    Input.mousereleased(x, y, button)
    GameState.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    Input.mousemoved(x, y, dx, dy)
    GameState.mousemoved(x, y, dx, dy)
end
