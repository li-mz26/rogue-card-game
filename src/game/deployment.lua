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

-- 滚轮滚动偏移
local cardListOffset = 0
local cardListMaxOffset = 0

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
    
    -- 当前选中的位置和具体槽位索引
    selectedPosition = UnitCards.POSITION.VANGUARD,
    selectedSlotIndex = 1,      -- 选中的具体槽位（1-5）
    
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
    
    -- 使用所有可用的卡牌
    local allCards = UnitCards.getAll()
    
    for _, card in ipairs(allCards) do
        table.insert(deploymentState.availableCards, card)
    end
end

-- ============================================================================
-- 布阵操作
-- ============================================================================

-- 添加卡牌到指定排的具体位置（任何卡牌可以放在任何位置）
function Deployment.addCardToRow(cardId, rowType, slotIndex)
    print("Adding card " .. cardId .. " to " .. rowType .. " slot " .. slotIndex)
    local card = UnitCards.createInstance(cardId, rowType)
    if not card then 
        print("Failed to create card instance")
        return false 
    end
    
    -- 大营特殊处理（只能有一个）
    if rowType == UnitCards.POSITION.COMMAND then
        deploymentState.selectedCommand = card
        print("Command set")
        return true
    end
    
    -- 获取该排的数据
    local rowTable = Deployment.getRowTable(rowType)
    if not rowTable then
        print("Failed to get row table for " .. rowType)
        return false
    end
    
    local maxCount = deploymentState.rowCounts[rowType]
    
    -- 检查索引是否有效
    if slotIndex < 1 or slotIndex > maxCount then
        print("无效的槽位索引: " .. slotIndex .. " (max: " .. maxCount .. ")")
        return false
    end
    
    -- 如果该位置已有卡牌，先移除
    if rowTable[slotIndex] then
        rowTable[slotIndex] = nil
    end
    
    -- 直接设置到指定位置
    rowTable[slotIndex] = card
    print("Card added successfully")
    return true
end

-- 从排中移除卡牌
function Deployment.removeCardFromRow(rowType, index)
    local rowTable = Deployment.getRowTable(rowType)
    if not rowTable then return false end
    
    local maxCount = deploymentState.rowCounts[rowType]
    if index >= 1 and index <= maxCount then
        rowTable[index] = nil  -- 直接设为nil，不使用table.remove
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
        Deployment.addCardToRow(randomCard.id, UnitCards.POSITION.COMMAND, 1)
    end
    
    -- 随机填充各排（从左到右填充）
    local allCardIds = {}
    for _, card in ipairs(deploymentState.availableCards) do
        table.insert(allCardIds, card.id)
    end
    
    local function fillRow(rowType, count)
        for i = 1, count do
            if #allCardIds > 0 then
                local randomIndex = math.random(#allCardIds)
                local cardId = allCardIds[randomIndex]
                local success = Deployment.addCardToRow(cardId, rowType, i)
                if not success then
                    break
                end
            end
        end
    end
    
    fillRow(UnitCards.POSITION.VANGUARD, deploymentState.rowCounts.vanguard)
    fillRow(UnitCards.POSITION.CENTER, deploymentState.rowCounts.center)
    fillRow(UnitCards.POSITION.REAR, deploymentState.rowCounts.rear)
end

-- 计算排中实际卡牌数量（包括分散存储的）
local function countCardsInRow(rowTable, maxCount)
    local count = 0
    for i = 1, maxCount do
        if rowTable[i] then count = count + 1 end
    end
    return count
end

-- 检查布阵是否完成
function Deployment.isComplete()
    -- 必须有大营
    if not deploymentState.selectedCommand then
        -- print("No command selected")
        return false
    end
    
    local vanguardCount = countCardsInRow(deploymentState.vanguardCards, deploymentState.rowCounts.vanguard)
    local centerCount = countCardsInRow(deploymentState.centerCards, deploymentState.rowCounts.center)
    local rearCount = countCardsInRow(deploymentState.rearCards, deploymentState.rowCounts.rear)
    
    -- 每排至少要有1个单位
    if vanguardCount == 0 then
        -- print("No vanguard cards")
        return false
    end
    if centerCount == 0 then
        -- print("No center cards")
        return false
    end
    if rearCount == 0 then
        -- print("No rear cards")
        return false
    end
    
    -- print("Complete! V:" .. vanguardCount .. " C:" .. centerCount .. " R:" .. rearCount)
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
    local startX = 20
    local startY = 50
    local cardWidth = 90
    local cardHeight = 120
    local gap = 6
    
    -- 绘制大营
    local isCommandSelected = deploymentState.selectedPosition == UnitCards.POSITION.COMMAND
    love.graphics.setColor(isCommandSelected and 1 or 0.9, isCommandSelected and 0.9 or 0.7, isCommandSelected and 0.5 or 0.3)
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    love.graphics.print("大营" .. (isCommandSelected and " <-" or ""), startX, startY)
    
    local commandY = startY + 18
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
        love.graphics.print(isCommandSelected and "选卡牌" or "点击", startX + 20, commandY + 50)
    end
    
    -- 存储大营点击区域（整个卡牌区域，包括空槽位）
    if not Deployment.clickAreas then Deployment.clickAreas = {} end
    table.insert(Deployment.clickAreas, {
        type = "slot",
        rowType = UnitCards.POSITION.COMMAND,
        index = 1,
        x = startX, y = commandY,
        width = cardWidth, height = cardHeight
    })
    
    -- 绘制各排
    local rows = {
        { key = "vanguard", name = "先锋", type = UnitCards.POSITION.VANGUARD, cards = deploymentState.vanguardCards, count = deploymentState.rowCounts.vanguard, y = startY + 140 },
        { key = "center", name = "中军", type = UnitCards.POSITION.CENTER, cards = deploymentState.centerCards, count = deploymentState.rowCounts.center, y = startY + 280 },
        { key = "rear", name = "殿后", type = UnitCards.POSITION.REAR, cards = deploymentState.rearCards, count = deploymentState.rowCounts.rear, y = startY + 420 }
    }
    
    for _, row in ipairs(rows) do
        -- 排名称
        local isRowSelected = deploymentState.selectedPosition == row.type
        love.graphics.setColor(isRowSelected and 1 or 0.9, isRowSelected and 0.9 or 0.7, isRowSelected and 0.5 or 0.3)
        love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
        
        -- 计算该排实际有多少卡牌（包括nil）
        local cardCount = 0
        for j = 1, row.count do
            if row.cards[j] then cardCount = cardCount + 1 end
        end
        love.graphics.print(row.name .. "(" .. cardCount .. "/" .. row.count .. ")", startX, row.y)
        
        -- 数量调整按钮
        Deployment.drawRowCountButtons(startX + 130, row.y, row.key)
        
        -- 绘制卡牌槽位
        local rowStartX = startX
        for i = 1, row.count do
            local cardX = rowStartX + (i - 1) * (cardWidth + gap)
            local cardY = row.y + 18
            local isSlotSelected = isRowSelected and deploymentState.selectedSlotIndex == i
            local hasCard = row.cards[i] ~= nil
            
            if hasCard then
                -- 有卡牌
                Deployment.drawCard(row.cards[i], cardX, cardY, cardWidth, cardHeight, row.type)
                -- 如果选中了这个槽位，画一个高亮边框
                if isSlotSelected then
                    love.graphics.setColor(1, 0.8, 0.2)
                    love.graphics.setLineWidth(3)
                    love.graphics.rectangle("line", cardX - 2, cardY - 2, cardWidth + 4, cardHeight + 4, 5)
                    love.graphics.setLineWidth(1)
                end
            else
                -- 空槽位
                if isSlotSelected then
                    love.graphics.setColor(0.3, 0.3, 0.35)
                    love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight, 5)
                    love.graphics.setColor(1, 0.8, 0.2)
                    love.graphics.setLineWidth(3)
                    love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight, 5)
                    love.graphics.setLineWidth(1)
                    love.graphics.setColor(1, 0.8, 0.2)
                    love.graphics.print("+", cardX + 40, cardY + 50)
                else
                    love.graphics.setColor(0.15, 0.15, 0.2)
                    love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight, 5)
                    love.graphics.setColor(0.3, 0.3, 0.35)
                    love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight, 5)
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.print("-", cardX + 40, cardY + 50)
                end
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
    local rarityColor = UnitCards.getRarityColor(card.rarity)
    
    -- 卡牌背景
    love.graphics.setColor(0.25, 0.25, 0.3)
    love.graphics.rectangle("fill", x, y, width, height, 4)
    
    -- 稀有度边框
    love.graphics.setColor(rarityColor[1], rarityColor[2], rarityColor[3])
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 4)
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
    love.graphics.rectangle("fill", x + 2, y + 2, width - 4, 18, 2)
    
    -- 卡牌名称
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
    love.graphics.print(card.name, x + 4, y + 3)
    
    -- 称号
    love.graphics.setColor(0.8, 0.8, 0.6)
    love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
    love.graphics.print(card.title or "", x + 4, y + 22)
    
    -- 属性
    love.graphics.setColor(0.9, 0.7, 0.3)
    love.graphics.setFont(chineseFont[10] or love.graphics.newFont(10))
    local statsY = y + 38
    local stats = {}
    if card.hp and card.hp > 0 then table.insert(stats, "HP:" .. card.hp) end
    if card.attack and card.attack > 0 then table.insert(stats, "ATK:" .. card.attack) end
    if card.defense and card.defense > 0 then table.insert(stats, "DEF:" .. card.defense) end
    if #stats > 0 then
        love.graphics.print(table.concat(stats, " "), x + 4, statsY)
    end
    
    -- 能力简述
    if card.abilities and #card.abilities > 0 then
        love.graphics.setColor(0.6, 0.8, 1)
        love.graphics.setFont(chineseFont[8] or love.graphics.newFont(8))
        love.graphics.printf(card.abilities[1].desc, x + 4, y + height - 30, width - 8, "left")
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
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    love.graphics.print("可选武将 (滚轮滚动)", panelX + 10, panelY + 8)
    
    -- 计算滚动相关
    local cardHeight = 50
    local cardGap = 6
    local totalCardHeight = cardHeight + cardGap
    local visibleHeight = panelHeight - 50
    local totalHeight = #deploymentState.availableCards * totalCardHeight
    cardListMaxOffset = math.max(0, totalHeight - visibleHeight)
    
    -- 裁剪区域（只显示面板内的内容）
    love.graphics.setStencilTest("greater", 0)
    love.graphics.rectangle("fill", panelX, panelY + 30, panelWidth, panelHeight - 30)
    love.graphics.setStencilTest()
    
    -- 使用 scissor 裁剪
    love.graphics.setScissor(panelX, panelY + 30, panelWidth, panelHeight - 30)
    
    -- 显示所有卡牌（支持滚动）
    local startY = panelY + 40 - cardListOffset
    
    for i, card in ipairs(deploymentState.availableCards) do
        local cardY = startY + (i - 1) * totalCardHeight
        
        -- 只绘制可见的卡牌
        if cardY + cardHeight >= panelY + 30 and cardY <= panelY + panelHeight - 10 then
            -- 卡牌背景
            local rarityColor = UnitCards.getRarityColor(card.rarity)
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", panelX + 10, cardY, panelWidth - 20, cardHeight, 3)
            love.graphics.setColor(rarityColor[1], rarityColor[2], rarityColor[3])
            love.graphics.rectangle("line", panelX + 10, cardY, panelWidth - 20, cardHeight, 3)
            
            -- 卡牌名称
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
            love.graphics.print(card.name, panelX + 15, cardY + 4)
            
            -- 称号
            love.graphics.setColor(0.8, 0.8, 0.6)
            love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
            love.graphics.print(card.title, panelX + 15, cardY + 18)
            
            -- 说明
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.setFont(chineseFont[8] or love.graphics.newFont(8))
            love.graphics.printf(card.description, panelX + 15, cardY + 32, panelWidth - 30, "left")
            
            -- 存储点击区域（使用屏幕坐标，不考虑滚动偏移）
            if not Deployment.clickAreas then Deployment.clickAreas = {} end
            table.insert(Deployment.clickAreas, {
                type = "card",
                cardId = card.id,
                x = panelX + 10, 
                y = cardY + cardListOffset,  -- 加回偏移量，使用屏幕坐标
                width = panelWidth - 20, 
                height = cardHeight
            })
        end
    end
    
    -- 恢复 scissor
    love.graphics.setScissor()
    
    -- 绘制滚动条（如果有）
    if cardListMaxOffset > 0 then
        local scrollbarHeight = visibleHeight * (visibleHeight / totalHeight)
        local scrollbarY = panelY + 30 + (cardListOffset / cardListMaxOffset) * (visibleHeight - scrollbarHeight)
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.rectangle("fill", panelX + panelWidth - 8, scrollbarY, 6, scrollbarHeight, 3)
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
    local isComplete = Deployment.isComplete()
    print("isComplete: " .. tostring(isComplete))
    table.insert(buttons, {
        text = "确认",
        x = screenWidth - 140,
        y = screenHeight - 70,
        width = 120,
        height = 40,
        enabled = isComplete,
        onClick = function()
            print("Confirm button clicked!")
            if Deployment.isComplete() then
                print("Deployment complete! Switching to game...")
                -- 获取布阵数据并传递给 battle
                local deploymentResult = Deployment.getDeploymentResult()
                print("Deployment result: " .. tostring(deploymentResult))
                local Battle = require('src.game.battle')
                Battle.setDeploymentData({
                    player1 = deploymentResult,
                    player2 = nil  -- AI will auto-deploy
                })
                -- 切换到战斗状态
                local GameState = require('src.game.gamestate')
                GameState.switch("game")
            else
                print("Deployment not complete yet!")
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

function Deployment.wheelmoved(x, y)
    -- 滚轮滚动卡牌列表
    local panelX = love.graphics.getWidth() - 320
    local panelY = 80
    local panelWidth = 300
    local panelHeight = love.graphics.getHeight() - 160
    
    local mx, my = love.mouse.getPosition()
    -- 检查鼠标是否在卡牌列表区域内
    if mx >= panelX and mx <= panelX + panelWidth and my >= panelY and my <= panelY + panelHeight then
        cardListOffset = cardListOffset - y * 30  -- 每次滚动30像素
        -- 限制滚动范围
        cardListOffset = math.max(0, math.min(cardListMaxOffset, cardListOffset))
    end
end

-- 处理点击（需要在draw之后调用）
function Deployment.handleClick(x, y)
    if not Deployment.clickAreas then return end
    
    for _, area in ipairs(Deployment.clickAreas) do
        if x >= area.x and x <= area.x + area.width
           and y >= area.y and y <= area.y + area.height then
            
            if area.type == "card" then
                -- 点击了卡牌，添加到当前选中的具体槽位
                Deployment.addCardToRow(area.cardId, deploymentState.selectedPosition, deploymentState.selectedSlotIndex)
                return true
                
            elseif area.type == "positionTab" then
                -- 点击了位置标签，切换选中位置
                deploymentState.selectedPosition = area.position
                return true
                
            elseif area.type == "slot" then
                -- 点击了槽位，选中该位置和具体索引
                deploymentState.selectedPosition = area.rowType
                deploymentState.selectedSlotIndex = area.index
                
                -- 处理大营特殊逻辑
                if area.rowType == UnitCards.POSITION.COMMAND then
                    if deploymentState.selectedCommand then
                        -- 如果已有大营，点击移除它
                        deploymentState.selectedCommand = nil
                    end
                    return true
                end
                
                -- 处理其他排：只是选中位置，不移除卡牌（除非再次点击已有卡牌的槽位）
                local rowTable = Deployment.getRowTable(area.rowType)
                if rowTable and rowTable[area.index] then
                    -- 如果该位置已有卡牌，点击移除它
                    rowTable[area.index] = nil
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
