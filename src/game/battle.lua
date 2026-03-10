--[[
    战斗系统
--]]

local Battle = {}

-- 游戏对象
local player = nil
local enemies = {}
local cards = {}
local currentTurn = 1

-- 中文字体
local chineseFont = {}

-- 加载中文字体
local function loadChineseFonts()
    local fontPaths = {
        "C:/Windows/Fonts/simhei.ttf",    -- 黑体 (推荐)
        "C:/Windows/Fonts/simkai.ttf",    -- 楷体
        "C:/Windows/Fonts/simsun.ttc",    -- 宋体
        "C:/Windows/Fonts/msyh.ttc",      -- 微软雅黑
        "C:/Windows/Fonts/msyhbd.ttc",    -- 微软雅黑粗体
    }
    
    for _, path in ipairs(fontPaths) do
        local success = pcall(function()
            chineseFont[10] = love.graphics.newFont(path, 10)
            chineseFont[12] = love.graphics.newFont(path, 12)
            chineseFont[16] = love.graphics.newFont(path, 16)
            chineseFont[18] = love.graphics.newFont(path, 18)
            chineseFont[20] = love.graphics.newFont(path, 20)
        end)
        if success then
            print("成功加载字体: " .. path)
            return true
        end
    end
    
    print("警告: 未找到中文字体")
    return false
end

function Battle.init()
    -- 加载字体
    if not chineseFont[16] then
        loadChineseFonts()
    end
    
    print("初始化战斗...")
    
    -- 初始化玩家
    player = {
        hp = 100,
        maxHp = 100,
        energy = 3,
        maxEnergy = 3,
        hand = {},
        deck = {},
        discard = {}
    }
    
    -- 初始化牌组
    Battle.initDeck()
    
    -- 洗牌并抽初始手牌
    Battle.shuffleDeck()
    Battle.drawCards(5)
    
    -- 初始化敌人
    enemies = {}
    table.insert(enemies, {
        name = "史莱姆",
        hp = 50,
        maxHp = 50,
        intent = "攻击"
    })
    
    currentTurn = 1
end

function Battle.initDeck()
    -- 创建基础牌组
    player.deck = {}
    
    -- 添加攻击牌
    for i = 1, 5 do
        table.insert(player.deck, {
            name = "攻击",
            type = "attack",
            cost = 1,
            damage = 6,
            description = "造成 6 点伤害"
        })
    end
    
    -- 添加防御牌
    for i = 1, 5 do
        table.insert(player.deck, {
            name = "防御",
            type = "defense",
            cost = 1,
            block = 5,
            description = "获得 5 点格挡"
        })
    end
end

function Battle.shuffleDeck()
    -- Fisher-Yates 洗牌算法
    for i = #player.deck, 2, -1 do
        local j = math.random(i)
        player.deck[i], player.deck[j] = player.deck[j], player.deck[i]
    end
end

function Battle.drawCards(count)
    for i = 1, count do
        if #player.deck > 0 then
            local card = table.remove(player.deck)
            table.insert(player.hand, card)
        elseif #player.discard > 0 then
            -- 弃牌堆洗牌形成新牌组
            player.deck = player.discard
            player.discard = {}
            Battle.shuffleDeck()
            local card = table.remove(player.deck)
            table.insert(player.hand, card)
        end
    end
end

function Battle.update(dt)
    -- 战斗逻辑更新
end

function Battle.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- 背景
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- 绘制玩家信息
    Battle.drawPlayer(screenWidth, screenHeight)
    
    -- 绘制敌人
    Battle.drawEnemies(screenWidth, screenHeight)
    
    -- 绘制手牌
    Battle.drawHand(screenWidth, screenHeight)
    
    -- 绘制UI
    Battle.drawUI(screenWidth, screenHeight)
end

function Battle.drawPlayer(screenWidth, screenHeight)
    local px, py = 100, screenHeight - 250
    
    -- 玩家区域背景
    love.graphics.setColor(0.2, 0.4, 0.3)
    love.graphics.rectangle("fill", px - 20, py - 20, 200, 150, 10)
    
    -- 玩家名称
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(chineseFont[20] or love.graphics.newFont(20))
    love.graphics.print("玩家", px, py)
    
    -- HP条
    local hpPercent = player.hp / player.maxHp
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", px, py + 35, 150, 20)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", px, py + 35, 150 * hpPercent, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(player.hp .. "/" .. player.maxHp, px + 50, py + 35)
    
    -- 能量
    love.graphics.setColor(0.2, 0.5, 0.8)
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    love.graphics.print("能量: " .. player.energy .. "/" .. player.maxEnergy, px, py + 65)
end

function Battle.drawEnemies(screenWidth, screenHeight)
    local startX = screenWidth - 300
    local y = 150
    
    for i, enemy in ipairs(enemies) do
        local x = startX - (i - 1) * 220
        
        -- 敌人背景
        love.graphics.setColor(0.4, 0.2, 0.2)
        love.graphics.rectangle("fill", x, y, 180, 120, 10)
        
        -- 敌人信息
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(chineseFont[18] or love.graphics.newFont(18))
        love.graphics.print(enemy.name, x + 10, y + 10)
        
        -- HP条
        local hpPercent = enemy.hp / enemy.maxHp
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", x + 10, y + 40, 160, 15)
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.rectangle("fill", x + 10, y + 40, 160 * hpPercent, 15)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(enemy.hp .. "/" .. enemy.maxHp, x + 60, y + 40)
        
        -- 意图
        love.graphics.setColor(0.9, 0.7, 0.3)
        love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
        love.graphics.print("意图: " .. enemy.intent, x + 10, y + 70)
    end
end

function Battle.drawHand(screenWidth, screenHeight)
    local cardWidth = 100
    local cardHeight = 140
    local spacing = 20
    local totalWidth = #player.hand * cardWidth + (#player.hand - 1) * spacing
    local startX = (screenWidth - totalWidth) / 2
    local y = screenHeight - 200
    
    for i, card in ipairs(player.hand) do
        local x = startX + (i - 1) * (cardWidth + spacing)
        
        -- 卡牌背景
        love.graphics.setColor(0.25, 0.25, 0.3)
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 5)
        
        -- 卡牌边框
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight, 5)
        
        -- 费用
        love.graphics.setColor(0.3, 0.5, 0.8)
        love.graphics.circle("fill", x + 15, y + 15, 12)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(tostring(card.cost), x + 10, y + 8)
        
        -- 卡牌名称
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
        love.graphics.print(card.name, x + 5, y + 35)
        
        -- 描述
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setFont(chineseFont[10] or love.graphics.newFont(10))
        love.graphics.printf(card.description, x + 5, y + 60, cardWidth - 10, "left")
    end
end

function Battle.drawUI(screenWidth, screenHeight)
    -- 回合数
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    love.graphics.print("回合 " .. currentTurn, 20, 20)
    
    -- 结束回合按钮
    local btnX = screenWidth - 150
    local btnY = screenHeight - 100
    love.graphics.setColor(0.8, 0.6, 0.3)
    love.graphics.rectangle("fill", btnX, btnY, 120, 40, 5)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    love.graphics.print("结束回合", btnX + 25, btnY + 10)
end

function Battle.exit()
    print("退出战斗...")
end

return Battle
