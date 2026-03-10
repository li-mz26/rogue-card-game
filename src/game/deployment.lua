--[[
    布阵系统
    玩家选择历史人物卡牌并部署到阵型中
--]]

local Deployment = {}
local UnitCards = require('src.cards.unit_cards')

-- 中文字体
local chineseFont = {}

-- 点击区域（在draw中填充，在mousepressed中使用）
Deployment.clickAreas = {}

-- 布阵状态
local deploymentState = {
    selectedCommand = nil,      -- 选择的大营卡牌
    vanguardCards = {},         -- 先锋卡牌列表
    centerCards = {},           -- 中军卡牌列表
    rearCards = {},             -- 殿后卡牌列表
    
    -- 每排单位数量（可调整）
    rowCounts = {
        vanguard = 3,
        center = 3,
        rear = 3
    },
    
    -- 当前选中的位置类型（用于放置卡牌）
    selectedPosition = UnitCards.POSITION.VANGUARD,
    
    -- 可用卡牌池（玩家拥有的卡牌）
    availableCards = {},
    
    playerId = 1
}

-- 加载字体
local function loadChineseFonts()
    local fontPaths = {
        "assets/fonts/simhei.ttf",
        "assets/fonts/simkai.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/simkai.ttf",
    }
    
    for _, path in ipairs(fontPaths) do
        local success = pcall(function()
            chineseFont[12] = love.graphics.newFont(path, 12)
            chineseFont[14] = love.graphics.newFont(path, 14)
            chineseFont[16] = love.graphics.newFont(path, 16)
            chineseFont[18] = love.graphics.newFont(path, 18)
            chineseFont[20] = love.graphics.newFont(path, 20)
            chineseFont[24] = love.graphics.newFont(path, 24)
        end)
        if success then
            return true
        end
    end
    return false
end

-- ============================================================================
-- 初始化
-- ============================================================================

function Deployment.init(playerId)
    loadChineseFonts()
    
    deploymentState.playerId = playerId or 1
    
    -- 清空当前选择
    deploymentState.selectedCommand = nil
    deploymentState.vanguardCards = {}
    deploymentState.centerCards = {}
    deploymentState.rearCards = {}
    deploymentState.selectedSlot = nil
    
    -- 重置每排数量
    deploymentState.rowCounts = {
        vanguard = 3,
        center = 3,
        rear = 3
    }
    
    -- 初始化可用卡牌（这里应该从玩家存档加载，暂时用所有卡牌）
    Deployment.initAvailableCards()
    
    print("布阵系统初始化完成")
end

-- 初始化可用卡牌池
function Deployment.initAvailableCards()
    deploymentState.availableCards = {}
    
    -- 所有可用的人物卡牌（不再按位置限制）
    local defaultCards = {
        "liu_bei", "cao_cao", "sun_quan",           -- 君主
        "guan_yu", "zhang_fei", "zhao_yun", "dian_wei", "zhang_liao",  -- 武将
        "zhuge_liang", "zhou_yu", "simayi", "xun_yu", "jiang_wei",    -- 谋士
        "huang_zhong", "tai_shi_ci"                 -- 弓将
    }
    
    for _, cardId in ipairs(defaultCards) do
        local template = UnitCards.getById(cardId)
        if template then
            -- 只复制基础信息，不创建实例（位置在放置时确定）
            table.insert(deploymentState.availableCards, template)
        end
    end
end

-- ============================================================================
-- 布阵操作
-- ============================================================================

-- 添加卡牌到指定排（任何卡牌可以放在任何位置）
function Deployment.addCardToRow(cardId, rowType)
    local card = UnitCards.createInstance(cardId, rowType)
    if not card then return false end
    
    -- 大营特殊处理（只能有一个）
    if rowType == UnitCards.POSITION.COMMAND then
        deploymentState.selectedCommand = card
        return true
    end
    
    -- 检查是否还有空位
    local rowTable = Deployment.getRowTable(rowType)
    local maxCount = deploymentState.rowCounts[rowType]
    
    if #rowTable >= maxCount then
        print("该排已满")
        return false
    end
    
    table.insert(rowTable, card)
    return true
end

-- 从排中移除卡牌
function Deployment.removeCardFromRow(rowType, index)
    local rowTable = Deployment.getRowTable(rowType)
    if index >= 1 and index <= #rowTable then
        table.remove(rowTable, index)
        return true
    end
    return false
end

-- 获取排对应的表格
function Deployment.getRowTable(rowType)
    if rowType == UnitCards.POSITION.VANGUARD then
        return deploymentState.vanguardCards
    elseif rowType == UnitCards.POSITION.CENTER then
        return deploymentState.centerCards
    elseif rowType == UnitCards.POSITION.REAR then
        return deploymentState.rearCards
    end
    return nil
end

-- 自动布阵（快速开始）
function Deployment.autoDeploy()
    -- 清空当前布阵
    deploymentState.selectedCommand = nil
    deploymentState.vanguardCards = {}
    deploymentState.centerCards = {}
    deploymentState.rearCards = {}
    
    -- 随机选择大营
    local allCards = UnitCards.getAll()
    if #allCards > 0 then
        local randomCard = allCards[math.random(#allCards)]
        Deployment.addCardToRow(randomCard.id, UnitCards.POSITION.COMMAND)
    end
    
    -- 随机填充各排（不再限制类型）
    local allCardIds = {}
    for _, card in ipairs(deploymentState.availableCards) do
        table.insert(allCardIds, card.id)
    end
    
    local function fillRow(rowType, count)
        for i = 1, count do
            if #allCardIds > 0 then
                local randomIndex = math.random(#allCardIds)
                local cardId = allCardIds[randomIndex]
                local success = Deployment.addCardToRow(cardId, rowType)
                if not success then
                    -- 如果添加失败（比如满了），停止
                    break
                end
            end
        end
    end
    
    fillRow(UnitCards.POSITION.VANGUARD, deploymentState.rowCounts.vanguard)
    fillRow(UnitCards.POSITION.CENTER, deploymentState.rowCounts.center)
    fillRow(UnitCards.POSITION.REAR, deploymentState.rowCounts.rear)
end

-- 检查布阵是否完成
function Deployment.isComplete()
    -- 必须有大营
    if not deploymentState.selectedCommand then
        return false
    end
    
    -- 每排至少要有1个单位
    if #deploymentState.vanguardCards == 0 then
        return false
    end
    if #deploymentState.centerCards == 0 then
        return false
    end
    if #deploymentState.rearCards == 0 then
        return false
    end
    
    return true
end

-- 获取布阵结果
function Deployment.getDeploymentResult()
    return {
        command = deploymentState.selectedCommand,
        vanguard = deploymentState.vanguardCards,
        center = deploymentState.centerCards,
        rear = deploymentState.rearCards,
        rowCounts = deploymentState.rowCounts
    }
end

-- ============================================================================
-- 更新和绘制
-- ============================================================================

function Deployment.update(dt)
    -- 可以添加动画效果
end

function Deployment.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- 背景
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- 标题
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[24] or love.graphics.newFont(24))
    love.graphics.print("布阵阶段", 20, 20)
    
    -- 绘制阵型预览
    Deployment.drawFormationPreview(screenWidth, screenHeight)
    
    -- 绘制卡牌选择区
    Deployment.drawCardSelection(screenWidth, screenHeight)
    
    -- 绘制操作按钮
    Deployment.drawButtons(screenWidth, screenHeight)
    
    -- 绘制提示信息
    Deployment.drawInfo(screenWidth, screenHeight)
end

-- 绘制阵型预览
function Deployment.drawFormationPreview(screenWidth, screenHeight)
    local startX = 50
    local startY = 80
    local cardWidth = 120
    local cardHeight = 160
    local gap = 10
    
    -- 绘制大营
    local isCommandSelected = deploymentState.selectedPosition == UnitCards.POSITION.COMMAND
    love.graphics.setColor(isCommandSelected and 1 or 0.9, isCommandSelected and 0.9 or 0.7, isCommandSelected and 0.5 or 0.3)
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    love.graphics.print("大营 (1)" .. (isCommandSelected and " ←" or ""), startX, startY)
    
    local commandY = startY + 25
    if deploymentState.selectedCommand then
        Deployment.drawCard(deploymentState.selectedCommand, startX, commandY, cardWidth, cardHeight, UnitCards.POSITION.COMMAND)
    else
        -- 空槽位
        if isCommandSelected then
            love.graphics.setColor(0.3, 0.3, 0.35)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", startX, commandY, cardWidth, cardHeight, 5)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setFont(chineseFont[14] or love.graphics.newFont(14))
        love.graphics.print(isCommandSelected and "点击右侧卡牌" or "点击选择", startX + 20, commandY + 70)
    end
    
    -- 存储大营点击区域
    if not Deployment.clickAreas then Deployment.clickAreas = {} end
    table.insert(Deployment.clickAreas, {
        type = "positionTab",
        position = UnitCards.POSITION.COMMAND,
        x = startX, y = startY,
        width = cardWidth, height = 25
    })
    
    -- 绘制各排
    local rows = {
        { key = "vanguard", name = "先锋", type = UnitCards.POSITION.VANGUARD, cards = deploymentState.vanguardCards, count = deploymentState.rowCounts.vanguard, y = startY + 200 },
        { key = "center", name = "中军", type = UnitCards.POSITION.CENTER, cards = deploymentState.centerCards, count = deploymentState.rowCounts.center, y = startY + 380 },
        { key = "rear", name = "殿后", type = UnitCards.POSITION.REAR, cards = deploymentState.rearCards, count = deploymentState.rowCounts.rear, y = startY + 560 }
    }
    
    for _, row in ipairs(rows) do
        -- 排名称（高亮选中）
        local isSelected = deploymentState.selectedPosition == row.type
        love.graphics.setColor(isSelected and 1 or 0.9, isSelected and 0.9 or 0.7, isSelected and 0.5 or 0.3)
        love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
        love.graphics.print(row.name .. " (" .. #row.cards .. "/" .. row.count .. ")" .. (isSelected and " ←" or ""), startX, row.y)
        
        -- 数量调整按钮
        Deployment.drawRowCountButtons(startX + 180, row.y, row.key)
        
        -- 存储位置标签点击区域
        table.insert(Deployment.clickAreas, {
            type = "positionTab",
            position = row.type,
            x = startX, y = row.y,
            width = 120, height = 25
        })
        
        -- 绘制卡牌槽位
        local rowStartX = startX
        for i = 1, row.count do
            local cardX = rowStartX + (i - 1) * (cardWidth + gap)
            local cardY = row.y + 25
            
            if i <= #row.cards then
                Deployment.drawCard(row.cards[i], cardX, cardY, cardWidth, cardHeight, row.type)
            else
                -- 空槽位
                if isSelected then
                    love.graphics.setColor(0.25, 0.25, 0.3)
                else
                    love.graphics.setColor(0.15, 0.15, 0.2)
                end
                love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight, 5)
                love.graphics.setColor(0.3, 0.3, 0.35)
                love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight, 5)
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
                love.graphics.print(isSelected and "点击添加" or "空位", cardX + 35, cardY + 70)
            end
            
            -- 存储点击区域
            table.insert(Deployment.clickAreas, {
                type = "slot",
                rowType = row.type,
                index = i,
                x = cardX, y = cardY,
                width = cardWidth, height = cardHeight
            })
        end
    end
end

-- 绘制单张卡牌
function Deployment.drawCard(card, x, y, width, height, slotType)
    -- 稀有度颜色边框
    local rarityColor = UnitCards.getRarityColor(card.rarity)
    
    -- 卡牌背景
    love.graphics.setColor(0.25, 0.25, 0.3)
    love.graphics.rectangle("fill", x, y, width, height, 5)
    
    -- 稀有度边框
    love.graphics.setColor(rarityColor[1], rarityColor[2], rarityColor[3])
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 5)
    love.graphics.setLineWidth(1)
    
    -- 位置类型色块
    local typeColors = {
        command = {0.8, 0.6, 0.2},
        vanguard = {0.8, 0.2, 0.2},
        center = {0.2, 0.6, 0.8},
        rear = {0.2, 0.8, 0.4}
    }
    local tc = typeColors[slotType] or {0.5, 0.5, 0.5}
    love.graphics.setColor(tc[1], tc[2], tc[3], 0.3)
    love.graphics.rectangle("fill", x + 2, y + 2, width - 4, 25, 3)
    
    -- 卡牌名称
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(chineseFont[14] or love.graphics.newFont(14))
    love.graphics.print(card.name, x + 5, y + 5)
    
    -- 称号
    love.graphics.setColor(0.8, 0.8, 0.6)
    love.graphics.setFont(chineseFont[11] or love.graphics.newFont(11))
    love.graphics.print(card.title or "", x + 5, y + 30)
    
    -- 属性（根据放置位置的效果）
    love.graphics.setColor(0.9, 0.7, 0.3)
    love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
    local statsY = y + 50
    if card.hp and card.hp > 0 then
        love.graphics.print("生命: " .. card.hp, x + 5, statsY)
        statsY = statsY + 18
    end
    if card.attack and card.attack > 0 then
        love.graphics.print("攻击: " .. card.attack, x + 5, statsY)
        statsY = statsY + 18
    end
    if card.defense and card.defense > 0 then
        love.graphics.print("防御: " .. card.defense, x + 5, statsY)
    end
    
    -- 能力简述
    if card.abilities and #card.abilities > 0 then
        love.graphics.setColor(0.6, 0.8, 1)
        love.graphics.setFont(chineseFont[10] or love.graphics.newFont(10))
        love.graphics.printf(card.abilities[1].desc, x + 5, y + height - 45, width - 10, "left")
    end
end

-- 绘制数量调整按钮
function Deployment.drawRowCountButtons(x, y, rowKey)
    local btnWidth = 25
    local btnHeight = 25
    
    -- 减号按钮
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("fill", x, y, btnWidth, btnHeight, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(chineseFont[18] or love.graphics.newFont(18))
    love.graphics.print("-", x + 8, y + 2)
    
    -- 加号按钮
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("fill", x + btnWidth + 5, y, btnWidth, btnHeight, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("+", x + btnWidth + 10, y + 2)
    
    -- 存储点击区域
    table.insert(Deployment.clickAreas, {
        type = "adjustCount",
        rowKey = rowKey,
        delta = -1,
        x = x, y = y,
        width = btnWidth, height = btnHeight
    })
    table.insert(Deployment.clickAreas, {
        type = "adjustCount",
        rowKey = rowKey,
        delta = 1,
        x = x + btnWidth + 5, y = y,
        width = btnWidth, height = btnHeight
    })
end

-- 绘制卡牌选择区
function Deployment.drawCardSelection(screenWidth, screenHeight)
    local panelX = screenWidth - 320
    local panelY = 80
    local panelWidth = 300
    local panelHeight = screenHeight - 160
    
    -- 面板背景
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
    
    -- 标题
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[18] or love.graphics.newFont(18))
    love.graphics.print("可选武将 (点击添加到选中位置)", panelX + 10, panelY + 10)
    
    -- 显示所有卡牌（不再分类）
    local cardY = panelY + 40
    local cardHeight = 55
    local cardGap = 8
    
    for _, card in ipairs(deploymentState.availableCards) do
        if cardY + cardHeight < panelY + panelHeight - 10 then
            -- 卡牌背景
            local rarityColor = UnitCards.getRarityColor(card.rarity)
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", panelX + 10, cardY, panelWidth - 20, cardHeight, 3)
            love.graphics.setColor(rarityColor[1], rarityColor[2], rarityColor[3])
            love.graphics.rectangle("line", panelX + 10, cardY, panelWidth - 20, cardHeight, 3)
            
            -- 卡牌名称
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(chineseFont[13] or love.graphics.newFont(13))
            love.graphics.print(card.name, panelX + 15, cardY + 5)
            
            -- 称号
            love.graphics.setColor(0.8, 0.8, 0.6)
            love.graphics.setFont(chineseFont[10] or love.graphics.newFont(10))
            love.graphics.print(card.title, panelX + 15, cardY + 22)
            
            -- 说明
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
            love.graphics.printf(card.description, panelX + 15, cardY + 36, panelWidth - 30, "left")
            
            -- 存储点击区域
            if not Deployment.clickAreas then Deployment.clickAreas = {} end
            table.insert(Deployment.clickAreas, {
                type = "card",
                cardId = card.id,
                x = panelX + 10, y = cardY,
                width = panelWidth - 20, height = cardHeight
            })
            
            cardY = cardY + cardHeight + cardGap
        end
    end
end

-- 绘制操作按钮
function Deployment.drawButtons(screenWidth, screenHeight)
    local buttons = {}
    
    -- 自动布阵按钮
    table.insert(buttons, {
        text = "自动布阵",
        x = screenWidth - 320,
        y = screenHeight - 70,
        width = 90,
        height = 40,
        onClick = function()
            Deployment.autoDeploy()
        end
    })
    
    -- 清空按钮
    table.insert(buttons, {
        text = "清空",
        x = screenWidth - 220,
        y = screenHeight - 70,
        width = 70,
        height = 40,
        onClick = function()
            deploymentState.selectedCommand = nil
            deploymentState.vanguardCards = {}
            deploymentState.centerCards = {}
            deploymentState.rearCards = {}
        end
    })
    
    -- 确认按钮
    local canConfirm = Deployment.isComplete()
    table.insert(buttons, {
        text = "确认",
        x = screenWidth - 140,
        y = screenHeight - 70,
        width = 120,
        height = 40,
        enabled = canConfirm,
        onClick = function()
            if Deployment.isComplete() then
                -- 切换到战斗状态
                local GameState = require('src.game.gamestate')
                GameState.switch("game")
            end
        end
    })
    
    -- 绘制按钮
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    for _, btn in ipairs(buttons) do
        local mx, my = love.mouse.getPosition()
        local hovered = mx >= btn.x and mx <= btn.x + btn.width
                        and my >= btn.y and my <= btn.y + btn.height
        
        -- 按钮背景
        if btn.enabled == false then
            love.graphics.setColor(0.3, 0.3, 0.3)
        elseif hovered then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.3, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5)
        
        -- 按钮边框
        love.graphics.setColor(0.6, 0.7, 0.8)
        love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5)
        
        -- 按钮文字
        love.graphics.setColor(btn.enabled == false and 0.5 or 1, 1, 1)
        local textWidth = (chineseFont[16] or love.graphics.newFont(16)):getWidth(btn.text)
        love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2, btn.y + 10)
        
        -- 存储点击区域
        if not Deployment.clickAreas then Deployment.clickAreas = {} end
        table.insert(Deployment.clickAreas, {
            type = "button",
            onClick = btn.onClick,
            enabled = btn.enabled ~= false,
            x = btn.x, y = btn.y,
            width = btn.width, height = btn.height
        })
    end
end

-- 绘制提示信息
function Deployment.drawInfo(screenWidth, screenHeight)
    if not Deployment.isComplete() then
        love.graphics.setColor(0.9, 0.5, 0.3)
        love.graphics.setFont(chineseFont[14] or love.graphics.newFont(14))
        
        local messages = {}
        if not deploymentState.selectedCommand then
            table.insert(messages, "请选择大营卡牌")
        end
        if #deploymentState.vanguardCards == 0 then
            table.insert(messages, "先锋至少需要1个单位")
        end
        if #deploymentState.centerCards == 0 then
            table.insert(messages, "中军至少需要1个单位")
        end
        if #deploymentState.rearCards == 0 then
            table.insert(messages, "殿后至少需要1个单位")
        end
        
        for i, msg in ipairs(messages) do
            love.graphics.print(msg, 20, screenHeight - 30 - (#messages - i) * 20)
        end
    end
end

-- ============================================================================
-- 输入处理
-- ============================================================================

function Deployment.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- 使用已经计算好的点击区域（在draw中填充）
    Deployment.handleClick(x, y)
end

-- 处理点击（需要在draw之后调用）
function Deployment.handleClick(x, y)
    if not Deployment.clickAreas then return end
    
    for _, area in ipairs(Deployment.clickAreas) do
        if x >= area.x and x <= area.x + area.width
           and y >= area.y and y <= area.y + area.height then
            
            if area.type == "card" then
                -- 点击了卡牌，添加到当前选中的位置
                Deployment.addCardToRow(area.cardId, deploymentState.selectedPosition)
                return true
                
            elseif area.type == "positionTab" then
                -- 点击了位置标签，切换选中位置
                deploymentState.selectedPosition = area.position
                return true
                
            elseif area.type == "slot" then
                -- 点击了槽位，选中该位置并可以移除卡牌
                deploymentState.selectedPosition = area.rowType
                if area.index <= #Deployment.getRowTable(area.rowType) then
                    -- 如果有卡牌，移除它
                    Deployment.removeCardFromRow(area.rowType, area.index)
                end
                return true
                
            elseif area.type == "adjustCount" then
                -- 调整排的数量
                local currentCount = deploymentState.rowCounts[area.rowKey]
                local newCount = currentCount + area.delta
                deploymentState.rowCounts[area.rowKey] = math.max(1, math.min(5, newCount))
                
                -- 如果当前卡牌数量超过新数量，移除多余的
                local rowType = area.rowKey == "vanguard" and UnitCards.POSITION.VANGUARD
                             or area.rowKey == "center" and UnitCards.POSITION.CENTER
                             or UnitCards.POSITION.REAR
                local rowTable = Deployment.getRowTable(rowType)
                while #rowTable > deploymentState.rowCounts[area.rowKey] do
                    table.remove(rowTable)
                end
                return true
                
            elseif area.type == "button" then
                -- 点击了按钮
                if area.enabled ~= false and area.onClick then
                    area.onClick()
                end
                return true
            end
        end
    end
    
    return false
end

return Deployment
