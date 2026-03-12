--[[
    甯冮樀绯荤粺
    鐜╁閫夋嫨鍘嗗彶浜虹墿鍗＄墝骞堕儴缃插埌闃靛瀷涓?--]]

local Deployment = {}
local UnitCards = require('src.cards.unit_cards')

-- 涓枃瀛椾綋
local chineseFont = {}

-- 鐐瑰嚮鍖哄煙锛堝湪draw涓～鍏咃紝鍦╩ousepressed涓娇鐢級
Deployment.clickAreas = {}

-- 婊氳疆婊氬姩鍋忕Щ
local cardListOffset = 0
local cardListMaxOffset = 0

-- 甯冮樀鐘舵€?local deploymentState = {
    selectedCommand = nil,      -- 閫夋嫨鐨勫ぇ钀ュ崱鐗?    vanguardCards = {},         -- 鍏堥攱鍗＄墝鍒楄〃
    centerCards = {},           -- 涓啗鍗＄墝鍒楄〃
    rearCards = {},             -- 娈垮悗鍗＄墝鍒楄〃
    
    -- 姣忔帓鍗曚綅鏁伴噺锛堝彲璋冩暣锛?    rowCounts = {
        vanguard = 3,
        center = 3,
        rear = 3
    },
    
    -- 褰撳墠閫変腑鐨勪綅缃拰鍏蜂綋妲戒綅绱㈠紩
    selectedPosition = UnitCards.POSITION.VANGUARD,
    selectedSlotIndex = 1,      -- 閫変腑鐨勫叿浣撴Ы浣嶏紙1-5锛?    
    -- 鍙敤鍗＄墝姹狅紙鐜╁鎷ユ湁鐨勫崱鐗岋級
    availableCards = {},
    
    playerId = 1
}

local rarityOrder = {
    common = 1,
    uncommon = 2,
    rare = 3,
    legendary = 4
}

local rarityLabel = {
    common = "COMMON",
    uncommon = "UNCOMMON",
    rare = "RARE",
    legendary = "LEGENDARY"
}

local function getRarityStyle(rarity)
    local c = UnitCards.getRarityColor(rarity)
    local frame = {c[1], c[2], c[3]}
    local glow = {
        math.min(1, c[1] + 0.2),
        math.min(1, c[2] + 0.2),
        math.min(1, c[3] + 0.2)
    }
    local bg = {
        0.10 + c[1] * 0.12,
        0.10 + c[2] * 0.12,
        0.14 + c[3] * 0.12
    }
    return {
        frame = frame,
        glow = glow,
        bg = bg,
        label = rarityLabel[rarity] or "COMMON"
    }
end

local function drawRarityFrame(x, y, width, height, rarity, selected)
    local style = getRarityStyle(rarity)
    local pulse = 0.6 + 0.4 * math.sin(love.timer.getTime() * 2.5)
    local glowAlpha = (selected and 0.22 or 0.13) + pulse * 0.05

    love.graphics.setColor(style.glow[1], style.glow[2], style.glow[3], glowAlpha)
    love.graphics.rectangle("fill", x - 4, y - 4, width + 8, height + 8, 8)

    love.graphics.setColor(style.bg[1], style.bg[2], style.bg[3], 1)
    love.graphics.rectangle("fill", x, y, width, height, 6)

    love.graphics.setColor(0.07, 0.07, 0.1, 0.9)
    love.graphics.rectangle("fill", x + 3, y + 3, width - 6, height - 6, 5)

    love.graphics.setColor(style.frame[1], style.frame[2], style.frame[3], 0.95)
    love.graphics.setLineWidth(selected and 3 or 2)
    love.graphics.rectangle("line", x, y, width, height, 6)
    love.graphics.setLineWidth(1)
end

local function getCardArt(card)
    if card._artImage then return card._artImage end
    if card._artLoadFailed then return nil end
    if not card.artPath then return nil end

    local ok, img = pcall(love.graphics.newImage, card.artPath)
    if ok and img then
        card._artImage = img
        return card._artImage
    end

    card._artLoadFailed = true
    return nil
end

-- 鍔犺浇瀛椾綋
local function loadChineseFonts()
    local fontPaths = {
        "assets/fonts/simhei.ttf",
        "assets/fonts/simkai.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/simkai.ttf",
    }
    
    for _, path in ipairs(fontPaths) do
        local success = pcall(function()
            chineseFont[8] = love.graphics.newFont(path, 8)
            chineseFont[9] = love.graphics.newFont(path, 9)
            chineseFont[10] = love.graphics.newFont(path, 10)
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
-- 鍒濆鍖?-- ============================================================================
function Deployment.init(playerId)
    loadChineseFonts()
    
    deploymentState.playerId = playerId or 1
    
    -- 娓呯┖褰撳墠閫夋嫨
    deploymentState.selectedCommand = nil
    deploymentState.vanguardCards = {}
    deploymentState.centerCards = {}
    deploymentState.rearCards = {}
    deploymentState.selectedSlot = nil
    
    -- 閲嶇疆姣忔帓鏁伴噺
    deploymentState.rowCounts = {
        vanguard = 3,
        center = 3,
        rear = 3
    }
    
    -- 鍒濆鍖栧彲鐢ㄥ崱鐗岋紙杩欓噷搴旇浠庣帺瀹跺瓨妗ｅ姞杞斤紝鏆傛椂鐢ㄦ墍鏈夊崱鐗岋級
    Deployment.initAvailableCards()
    
    print("甯冮樀绯荤粺鍒濆鍖栧畬鎴?)
end

-- 鍒濆鍖栧彲鐢ㄥ崱鐗屾睜
function Deployment.initAvailableCards()
    deploymentState.availableCards = {}
    
    -- 浣跨敤鎵€鏈夊彲鐢ㄧ殑鍗＄墝
    local allCards = UnitCards.getAll()
    
    for _, card in ipairs(allCards) do
        table.insert(deploymentState.availableCards, card)
    end
end

-- ============================================================================
-- 甯冮樀鎿嶄綔
-- ============================================================================

-- 娣诲姞鍗＄墝鍒版寚瀹氭帓鐨勫叿浣撲綅缃紙浠讳綍鍗＄墝鍙互鏀惧湪浠讳綍浣嶇疆锛?
function Deployment.addCardToRow(cardId, rowType, slotIndex)
    print("Adding card " .. cardId .. " to " .. rowType .. " slot " .. slotIndex)
    local card = UnitCards.createInstance(cardId, rowType)
    if not card then 
        print("Failed to create card instance")
        return false 
    end
    
    -- 澶ц惀鐗规畩澶勭悊锛堝彧鑳芥湁涓€涓級
    if rowType == UnitCards.POSITION.COMMAND then
        deploymentState.selectedCommand = card
        print("Command set")
        return true
    end
    
    -- 鑾峰彇璇ユ帓鐨勬暟鎹?    local rowTable = Deployment.getRowTable(rowType)
    if not rowTable then
        print("Failed to get row table for " .. rowType)
        return false
    end
    
    local maxCount = deploymentState.rowCounts[rowType]
    
    -- 妫€鏌ョ储寮曟槸鍚︽湁鏁?    if slotIndex < 1 or slotIndex > maxCount then
        print("鏃犳晥鐨勬Ы浣嶇储寮? " .. slotIndex .. " (max: " .. maxCount .. ")")
        return false
    end
    
    -- 濡傛灉璇ヤ綅缃凡鏈夊崱鐗岋紝鍏堢Щ闄?    if rowTable[slotIndex] then
        rowTable[slotIndex] = nil
    end
    
    -- 鐩存帴璁剧疆鍒版寚瀹氫綅缃?    rowTable[slotIndex] = card
    print("Card added successfully")
    return true
end

-- 浠庢帓涓Щ闄ゅ崱鐗?
function Deployment.removeCardFromRow(rowType, index)
    local rowTable = Deployment.getRowTable(rowType)
    if not rowTable then return false end
    
    local maxCount = deploymentState.rowCounts[rowType]
    if index >= 1 and index <= maxCount then
        rowTable[index] = nil  -- 鐩存帴璁句负nil锛屼笉浣跨敤table.remove
        return true
    end
    return false
end

-- 鑾峰彇鎺掑搴旂殑琛ㄦ牸
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

-- 鑷姩甯冮樀锛堝揩閫熷紑濮嬶級
function Deployment.autoDeploy()
    -- 娓呯┖褰撳墠甯冮樀
    deploymentState.selectedCommand = nil
    deploymentState.vanguardCards = {}
    deploymentState.centerCards = {}
    deploymentState.rearCards = {}
    
    -- 闅忔満閫夋嫨澶ц惀
    local allCards = UnitCards.getAll()
    if #allCards > 0 then
        local randomCard = allCards[math.random(#allCards)]
        Deployment.addCardToRow(randomCard.id, UnitCards.POSITION.COMMAND, 1)
    end
    
    -- 闅忔満濉厖鍚勬帓锛堜粠宸﹀埌鍙冲～鍏咃級
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

-- 璁＄畻鎺掍腑瀹為檯鍗＄墝鏁伴噺锛堝寘鎷垎鏁ｅ瓨鍌ㄧ殑锛?
local function countCardsInRow(rowTable, maxCount)
    local count = 0
    for i = 1, maxCount do
        if rowTable[i] then count = count + 1 end
    end
    return count
end

-- 妫€鏌ュ竷闃垫槸鍚﹀畬鎴?
function Deployment.isComplete()
    -- 蹇呴』鏈夊ぇ钀?    if not deploymentState.selectedCommand then
        -- print("No command selected")
        return false
    end
    
    local vanguardCount = countCardsInRow(deploymentState.vanguardCards, deploymentState.rowCounts.vanguard)
    local centerCount = countCardsInRow(deploymentState.centerCards, deploymentState.rowCounts.center)
    local rearCount = countCardsInRow(deploymentState.rearCards, deploymentState.rowCounts.rear)
    
    -- 姣忔帓鑷冲皯瑕佹湁1涓崟浣?    if vanguardCount == 0 then
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

-- 鑾峰彇甯冮樀缁撴灉
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
-- 鏇存柊鍜岀粯鍒?-- ============================================================================
function Deployment.update(dt)
    -- 鍙互娣诲姞鍔ㄧ敾鏁堟灉
end

function Deployment.draw()
    -- 娓呯┖鐐瑰嚮鍖哄煙锛堟瘡甯ч噸鏂拌绠楋級
    Deployment.clickAreas = {}
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- 鑳屾櫙
    love.graphics.setColor(0.07, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setColor(0.16, 0.12, 0.08, 0.25)
    love.graphics.rectangle("fill", 0, 0, screenWidth, 80)
    love.graphics.setColor(0.08, 0.09, 0.14, 0.45)
    for i = 0, math.ceil(screenHeight / 40) do
        love.graphics.rectangle("fill", 0, i * 40, screenWidth, 1)
    end
    
    -- 鏍囬
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[24] or love.graphics.newFont(24))
    love.graphics.print("甯冮樀闃舵", 20, 20)
    
    -- 缁樺埗闃靛瀷棰勮
    Deployment.drawFormationPreview(screenWidth, screenHeight)
    
    -- 缁樺埗鍗＄墝閫夋嫨鍖?    Deployment.drawCardSelection(screenWidth, screenHeight)
    
    -- 缁樺埗鎿嶄綔鎸夐挳
    Deployment.drawButtons(screenWidth, screenHeight)
    
    -- 缁樺埗鎻愮ず淇℃伅
    Deployment.drawInfo(screenWidth, screenHeight)
end

-- 缁樺埗闃靛瀷棰勮
function Deployment.drawFormationPreview(screenWidth, screenHeight)
    local startX = 20
    local startY = 50
    local cardWidth = 90
    local cardHeight = 120
    local gap = 6
    
    -- 缁樺埗澶ц惀
    local isCommandSelected = deploymentState.selectedPosition == UnitCards.POSITION.COMMAND
    love.graphics.setColor(isCommandSelected and 1 or 0.9, isCommandSelected and 0.9 or 0.7, isCommandSelected and 0.5 or 0.3)
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    love.graphics.print("澶ц惀" .. (isCommandSelected and " <-" or ""), startX, startY)
    
    local commandY = startY + 18
    if deploymentState.selectedCommand then
        Deployment.drawCard(deploymentState.selectedCommand, startX, commandY, cardWidth, cardHeight, UnitCards.POSITION.COMMAND)
    else
        -- 绌烘Ы浣?        if isCommandSelected then
            love.graphics.setColor(0.3, 0.3, 0.35)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", startX, commandY, cardWidth, cardHeight, 5)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setFont(chineseFont[14] or love.graphics.newFont(14))
        love.graphics.print(isCommandSelected and "閫夊崱鐗? or "鐐瑰嚮", startX + 20, commandY + 50)
    end
    
    -- 瀛樺偍澶ц惀鐐瑰嚮鍖哄煙锛堟暣涓崱鐗屽尯鍩燂紝鍖呮嫭绌烘Ы浣嶏級
    table.insert(Deployment.clickAreas, {
        type = "slot",
        rowType = UnitCards.POSITION.COMMAND,
        index = 1,
        x = startX, y = commandY,
        width = cardWidth, height = cardHeight
    })
    
    -- 缁樺埗鍚勬帓
    local rows = {
        { key = "vanguard", name = "鍏堥攱", type = UnitCards.POSITION.VANGUARD, cards = deploymentState.vanguardCards, count = deploymentState.rowCounts.vanguard, y = startY + 140 },
        { key = "center", name = "涓啗", type = UnitCards.POSITION.CENTER, cards = deploymentState.centerCards, count = deploymentState.rowCounts.center, y = startY + 280 },
        { key = "rear", name = "娈垮悗", type = UnitCards.POSITION.REAR, cards = deploymentState.rearCards, count = deploymentState.rowCounts.rear, y = startY + 420 }
    }
    
    for _, row in ipairs(rows) do
        -- 鎺掑悕绉?        local isRowSelected = deploymentState.selectedPosition == row.type
        love.graphics.setColor(isRowSelected and 1 or 0.9, isRowSelected and 0.9 or 0.7, isRowSelected and 0.5 or 0.3)
        love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
        
        -- 璁＄畻璇ユ帓瀹為檯鏈夊灏戝崱鐗岋紙鍖呮嫭nil锛?        local cardCount = 0
        for j = 1, row.count do
            if row.cards[j] then cardCount = cardCount + 1 end
        end
        love.graphics.print(row.name .. "(" .. cardCount .. "/" .. row.count .. ")", startX, row.y)
        
        -- 鏁伴噺璋冩暣鎸夐挳
        Deployment.drawRowCountButtons(startX + 130, row.y, row.key)
        
        -- 缁樺埗鍗＄墝妲戒綅
        local rowStartX = startX
        for i = 1, row.count do
            local cardX = rowStartX + (i - 1) * (cardWidth + gap)
            local cardY = row.y + 18
            local isSlotSelected = isRowSelected and deploymentState.selectedSlotIndex == i
            local hasCard = row.cards[i] ~= nil
            
            if hasCard then
                -- 鏈夊崱鐗?                Deployment.drawCard(row.cards[i], cardX, cardY, cardWidth, cardHeight, row.type)
                -- 濡傛灉閫変腑浜嗚繖涓Ы浣嶏紝鐢讳竴涓珮浜竟妗?                if isSlotSelected then
                    love.graphics.setColor(1, 0.8, 0.2)
                    love.graphics.setLineWidth(3)
                    love.graphics.rectangle("line", cardX - 2, cardY - 2, cardWidth + 4, cardHeight + 4, 5)
                    love.graphics.setLineWidth(1)
                end
            else
                -- 绌烘Ы浣?                if isSlotSelected then
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
            
            -- 瀛樺偍鐐瑰嚮鍖哄煙
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

-- 缁樺埗鍗曞紶鍗＄墝
function Deployment.drawCard(card, x, y, width, height, slotType)
    local rarity = card.rarity or "common"
    local style = getRarityStyle(rarity)
    drawRarityFrame(x, y, width, height, rarity, false)

    -- 浣嶇疆绫诲瀷鑹插潡
    local typeColors = {
        command = {0.8, 0.6, 0.2},
        vanguard = {0.8, 0.2, 0.2},
        center = {0.2, 0.6, 0.8},
        rear = {0.2, 0.8, 0.4}
    }
    local tc = typeColors[slotType] or {0.5, 0.5, 0.5}
    love.graphics.setColor(tc[1], tc[2], tc[3], 0.35)
    love.graphics.rectangle("fill", x + 4, y + 4, width - 8, 16, 3)

    local artX, artY = x + 6, y + 24
    local artW, artH = width - 12, math.floor(height * 0.43)
    love.graphics.setColor(0.12, 0.13, 0.18, 1)
    love.graphics.rectangle("fill", artX, artY, artW, artH, 4)

    local artImage = getCardArt(card)
    if artImage then
        local sx = artW / artImage:getWidth()
        local sy = artH / artImage:getHeight()
        local scale = math.max(sx, sy)
        local drawW = artImage:getWidth() * scale
        local drawH = artImage:getHeight() * scale
        love.graphics.setScissor(artX, artY, artW, artH)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.draw(artImage, artX + (artW - drawW) / 2, artY + (artH - drawH) / 2, 0, scale, scale)
        love.graphics.setScissor()
    else
        love.graphics.setColor(style.frame[1], style.frame[2], style.frame[3], 0.28)
        love.graphics.rectangle("fill", artX + 4, artY + 4, artW - 8, artH - 8, 3)
        love.graphics.setColor(1, 1, 1, 0.55)
        love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
        love.graphics.printf("AI ART SLOT", artX, artY + artH / 2 - 5, artW, "center")
    end
    
    -- 鍗＄墝鍚嶇О
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
    love.graphics.print(card.name, x + 4, y + 3)

    love.graphics.setColor(style.frame[1], style.frame[2], style.frame[3], 0.9)
    love.graphics.setFont(chineseFont[8] or love.graphics.newFont(8))
    love.graphics.print(style.label, x + width - 52, y + 8)
    
    -- 绉板彿
    love.graphics.setColor(0.8, 0.8, 0.6)
    love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
    love.graphics.print(card.title or "", x + 4, y + 22)
    
    -- 灞炴€?
    love.graphics.setColor(0.9, 0.7, 0.3)
    love.graphics.setFont(chineseFont[10] or love.graphics.newFont(10))
    local statsY = artY + artH + 4
    local stats = {}
    if card.sendPower then table.insert(stats, string.format("S:%.2f", card.sendPower)) end
    if card.recvPower then table.insert(stats, string.format("R:%.2f", card.recvPower)) end
    if card.interceptPower then table.insert(stats, string.format("I:%.2f", card.interceptPower)) end
    if #stats > 0 then
        love.graphics.print(table.concat(stats, " "), x + 4, statsY)
    end

    local tagText = ""
    if card.tags then
        local tags = {}
        if card.tags.dynasty then table.insert(tags, card.tags.dynasty) end
        if card.tags.surname then table.insert(tags, card.tags.surname) end
        if card.tags.origin then table.insert(tags, card.tags.origin) end
        tagText = table.concat(tags, " / ")
    end
    if tagText ~= "" then
        love.graphics.setColor(0.72, 0.82, 0.95)
        love.graphics.setFont(chineseFont[8] or love.graphics.newFont(8))
        love.graphics.printf(tagText, x + 4, y + height - 32, width - 8, "left")
    end
    
    -- 鑳藉姏绠€杩?
    if card.abilities and #card.abilities > 0 then
        love.graphics.setColor(0.65, 0.86, 1)
        love.graphics.setFont(chineseFont[8] or love.graphics.newFont(8))
        love.graphics.printf(card.abilities[1].desc, x + 4, y + height - 16, width - 8, "left")
    end
end

-- 缁樺埗鏁伴噺璋冩暣鎸夐挳
function Deployment.drawRowCountButtons(x, y, rowKey)
    local btnWidth = 25
    local btnHeight = 25
    
    -- 鍑忓彿鎸夐挳
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("fill", x, y, btnWidth, btnHeight, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(chineseFont[18] or love.graphics.newFont(18))
    love.graphics.print("-", x + 8, y + 2)
    
    -- 鍔犲彿鎸夐挳
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("fill", x + btnWidth + 5, y, btnWidth, btnHeight, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("+", x + btnWidth + 10, y + 2)
    
    -- 瀛樺偍鐐瑰嚮鍖哄煙
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

-- 缁樺埗鍗＄墝閫夋嫨鍖?
function Deployment.drawCardSelection(screenWidth, screenHeight)
    local panelX = screenWidth - 320
    local panelY = 80
    local panelWidth = 300
    local panelHeight = screenHeight - 160
    
    -- 闈㈡澘鑳屾櫙
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
    
    -- 鏍囬
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    love.graphics.print("鍙€夋灏?(婊氳疆婊氬姩)", panelX + 10, panelY + 8)
    
    -- 璁＄畻婊氬姩鐩稿叧
    local cardHeight = 56
    local cardGap = 6
    local totalCardHeight = cardHeight + cardGap
    local visibleHeight = panelHeight - 50
    local totalHeight = #deploymentState.availableCards * totalCardHeight
    cardListMaxOffset = math.max(0, totalHeight - visibleHeight)
    
    -- 瑁佸壀鍖哄煙锛堝彧鏄剧ず闈㈡澘鍐呯殑鍐呭锛?    love.graphics.setStencilTest("greater", 0)
    love.graphics.rectangle("fill", panelX, panelY + 30, panelWidth, panelHeight - 30)
    love.graphics.setStencilTest()
    
    -- 浣跨敤 scissor 瑁佸壀
    love.graphics.setScissor(panelX, panelY + 30, panelWidth, panelHeight - 30)
    
    table.sort(deploymentState.availableCards, function(a, b)
        local ar = rarityOrder[a.rarity or "common"] or 1
        local br = rarityOrder[b.rarity or "common"] or 1
        if ar == br then
            return (a.name or "") < (b.name or "")
        end
        return ar > br
    end)

    -- 鏄剧ず鎵€鏈夊崱鐗岋紙鏀寔婊氬姩锛?    local startY = panelY + 40 - cardListOffset
    
    for i, card in ipairs(deploymentState.availableCards) do
        local cardY = startY + (i - 1) * totalCardHeight
        
        -- 鍙粯鍒跺彲瑙佺殑鍗＄墝
        if cardY + cardHeight >= panelY + 30 and cardY <= panelY + panelHeight - 10 then
            -- 鍗＄墝鑳屾櫙
            local style = getRarityStyle(card.rarity or "common")
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", panelX + 10, cardY, panelWidth - 20, cardHeight, 3)
            love.graphics.setColor(style.frame[1], style.frame[2], style.frame[3])
            love.graphics.rectangle("line", panelX + 10, cardY, panelWidth - 20, cardHeight, 3)
            love.graphics.setColor(style.frame[1], style.frame[2], style.frame[3], 0.25)
            love.graphics.rectangle("fill", panelX + 11, cardY + 1, 7, cardHeight - 2, 2)
            
            -- 鍗＄墝鍚嶇О
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
            love.graphics.print(card.name, panelX + 15, cardY + 4)
            love.graphics.setColor(style.frame[1], style.frame[2], style.frame[3])
            love.graphics.setFont(chineseFont[8] or love.graphics.newFont(8))
            love.graphics.print(style.label, panelX + panelWidth - 90, cardY + 4)
            
            -- 绉板彿
            love.graphics.setColor(0.8, 0.8, 0.6)
            love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
            love.graphics.print(card.title, panelX + 15, cardY + 18)
            
            -- 璇存槑
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.setFont(chineseFont[8] or love.graphics.newFont(8))
            love.graphics.printf(card.description, panelX + 15, cardY + 32, panelWidth - 30, "left")
            
            -- 瀛樺偍鐐瑰嚮鍖哄煙锛坈ardY 宸茬粡鏄睆骞曞潗鏍囷級
            table.insert(Deployment.clickAreas, {
                type = "card",
                cardId = card.id,
                x = panelX + 10, 
                y = cardY,  -- cardY 宸茬粡鏄噺鍘诲亸绉婚噺鍚庣殑灞忓箷鍧愭爣
                width = panelWidth - 20, 
                height = cardHeight
            })
        end
    end
    
    -- 鎭㈠ scissor
    love.graphics.setScissor()
    
    -- 缁樺埗婊氬姩鏉★紙濡傛灉鏈夛級
    if cardListMaxOffset > 0 then
        local scrollbarHeight = visibleHeight * (visibleHeight / totalHeight)
        local scrollbarY = panelY + 30 + (cardListOffset / cardListMaxOffset) * (visibleHeight - scrollbarHeight)
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.rectangle("fill", panelX + panelWidth - 8, scrollbarY, 6, scrollbarHeight, 3)
    end
end

-- 缁樺埗鎿嶄綔鎸夐挳
function Deployment.drawButtons(screenWidth, screenHeight)
    local buttons = {}
    
    -- 鑷姩甯冮樀鎸夐挳
    table.insert(buttons, {
        text = "鑷姩甯冮樀",
        x = screenWidth - 320,
        y = screenHeight - 70,
        width = 90,
        height = 40,
        onClick = function()
            Deployment.autoDeploy()
        end
    })
    
    -- 娓呯┖鎸夐挳
    table.insert(buttons, {
        text = "娓呯┖",
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
    
    -- 纭鎸夐挳
    local isComplete = Deployment.isComplete()
    -- print("isComplete: " .. tostring(isComplete))
    table.insert(buttons, {
        text = "纭",
        x = screenWidth - 140,
        y = screenHeight - 70,
        width = 120,
        height = 40,
        enabled = isComplete,
        onClick = function()
            print("Confirm button clicked!")
            if Deployment.isComplete() then
                print("Deployment complete! Switching to game...")
                -- 鑾峰彇甯冮樀鏁版嵁骞朵紶閫掔粰 battle
                local deploymentResult = Deployment.getDeploymentResult()
                print("Deployment result: " .. tostring(deploymentResult))
                local Battle = require('src.game.battle')
                Battle.setDeploymentData({
                    player1 = deploymentResult,
                    player2 = nil  -- AI will auto-deploy
                })
                -- 鍒囨崲鍒版垬鏂楃姸鎬?                local GameState = require('src.game.gamestate')
                GameState.switch("game")
            else
                print("Deployment not complete yet!")
            end
        end
    })
    
    -- 缁樺埗鎸夐挳
    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    for _, btn in ipairs(buttons) do
        local mx, my = love.mouse.getPosition()
        local hovered = mx >= btn.x and mx <= btn.x + btn.width
                        and my >= btn.y and my <= btn.y + btn.height
        
        -- 鎸夐挳鑳屾櫙
        if btn.enabled == false then
            love.graphics.setColor(0.3, 0.3, 0.3)
        elseif hovered then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.3, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5)
        
        -- 鎸夐挳杈规
        love.graphics.setColor(0.6, 0.7, 0.8)
        love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5)
        
        -- 鎸夐挳鏂囧瓧
        love.graphics.setColor(btn.enabled == false and 0.5 or 1, 1, 1)
        local textWidth = (chineseFont[16] or love.graphics.newFont(16)):getWidth(btn.text)
        love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2, btn.y + 10)
        
        -- 瀛樺偍鐐瑰嚮鍖哄煙
        table.insert(Deployment.clickAreas, {
            type = "button",
            onClick = btn.onClick,
            enabled = btn.enabled ~= false,
            x = btn.x, y = btn.y,
            width = btn.width, height = btn.height
        })
    end
end

-- 缁樺埗鎻愮ず淇℃伅
function Deployment.drawInfo(screenWidth, screenHeight)
    if not Deployment.isComplete() then
        love.graphics.setColor(0.9, 0.5, 0.3)
        love.graphics.setFont(chineseFont[14] or love.graphics.newFont(14))
        
        local messages = {}
        if not deploymentState.selectedCommand then
            table.insert(messages, "璇烽€夋嫨澶ц惀鍗＄墝")
        end
        if #deploymentState.vanguardCards == 0 then
            table.insert(messages, "鍏堥攱鑷冲皯闇€瑕?涓崟浣?)
        end
        if #deploymentState.centerCards == 0 then
            table.insert(messages, "涓啗鑷冲皯闇€瑕?涓崟浣?)
        end
        if #deploymentState.rearCards == 0 then
            table.insert(messages, "娈垮悗鑷冲皯闇€瑕?涓崟浣?)
        end
        
        for i, msg in ipairs(messages) do
            love.graphics.print(msg, 20, screenHeight - 30 - (#messages - i) * 20)
        end
    end
end

-- ============================================================================
-- 杈撳叆澶勭悊
-- ============================================================================
function Deployment.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- 浣跨敤宸茬粡璁＄畻濂界殑鐐瑰嚮鍖哄煙锛堝湪draw涓～鍏咃級
    Deployment.handleClick(x, y)
end

function Deployment.wheelmoved(x, y)
    -- 婊氳疆婊氬姩鍗＄墝鍒楄〃
    local panelX = love.graphics.getWidth() - 320
    local panelY = 80
    local panelWidth = 300
    local panelHeight = love.graphics.getHeight() - 160
    
    local mx, my = love.mouse.getPosition()
    -- 妫€鏌ラ紶鏍囨槸鍚﹀湪鍗＄墝鍒楄〃鍖哄煙鍐?    if mx >= panelX and mx <= panelX + panelWidth and my >= panelY and my <= panelY + panelHeight then
        cardListOffset = cardListOffset - y * 30  -- 姣忔婊氬姩30鍍忕礌
        -- 闄愬埗婊氬姩鑼冨洿
        cardListOffset = math.max(0, math.min(cardListMaxOffset, cardListOffset))
    end
end

-- 澶勭悊鐐瑰嚮锛堥渶瑕佸湪draw涔嬪悗璋冪敤锛?
function Deployment.handleClick(x, y)
    if not Deployment.clickAreas then return end
    
    for _, area in ipairs(Deployment.clickAreas) do
        if x >= area.x and x <= area.x + area.width
           and y >= area.y and y <= area.y + area.height then
            
            if area.type == "card" then
                -- 鐐瑰嚮浜嗗崱鐗岋紝娣诲姞鍒板綋鍓嶉€変腑鐨勫叿浣撴Ы浣?                Deployment.addCardToRow(area.cardId, deploymentState.selectedPosition, deploymentState.selectedSlotIndex)
                return true
                
            elseif area.type == "positionTab" then
                -- 鐐瑰嚮浜嗕綅缃爣绛撅紝鍒囨崲閫変腑浣嶇疆
                deploymentState.selectedPosition = area.position
                return true
                
            elseif area.type == "slot" then
                -- 鐐瑰嚮浜嗘Ы浣嶏紝閫変腑璇ヤ綅缃拰鍏蜂綋绱㈠紩
                deploymentState.selectedPosition = area.rowType
                deploymentState.selectedSlotIndex = area.index
                
                -- 澶勭悊澶ц惀鐗规畩閫昏緫
                if area.rowType == UnitCards.POSITION.COMMAND then
                    if deploymentState.selectedCommand then
                        -- 濡傛灉宸叉湁澶ц惀锛岀偣鍑荤Щ闄ゅ畠
                        deploymentState.selectedCommand = nil
                    end
                    return true
                end
                
                -- 澶勭悊鍏朵粬鎺掞細鍙槸閫変腑浣嶇疆锛屼笉绉婚櫎鍗＄墝锛堥櫎闈炲啀娆＄偣鍑诲凡鏈夊崱鐗岀殑妲戒綅锛?                local rowTable = Deployment.getRowTable(area.rowType)
                if rowTable and rowTable[area.index] then
                    -- 濡傛灉璇ヤ綅缃凡鏈夊崱鐗岋紝鐐瑰嚮绉婚櫎瀹?                    rowTable[area.index] = nil
                end
                return true
                
            elseif area.type == "adjustCount" then
                -- 璋冩暣鎺掔殑鏁伴噺
                local currentCount = deploymentState.rowCounts[area.rowKey]
                local newCount = currentCount + area.delta
                deploymentState.rowCounts[area.rowKey] = math.max(1, math.min(5, newCount))
                
                -- 濡傛灉褰撳墠鍗＄墝鏁伴噺瓒呰繃鏂版暟閲忥紝绉婚櫎澶氫綑鐨?                local rowType = area.rowKey == "vanguard" and UnitCards.POSITION.VANGUARD
                             or area.rowKey == "center" and UnitCards.POSITION.CENTER
                             or UnitCards.POSITION.REAR
                local rowTable = Deployment.getRowTable(rowType)
                while #rowTable > deploymentState.rowCounts[area.rowKey] do
                    table.remove(rowTable)
                end
                return true
                
            elseif area.type == "button" then
                -- 鐐瑰嚮浜嗘寜閽?                if area.enabled ~= false and area.onClick then
                    area.onClick()
                end
                return true
            end
        end
    end
    
    return false
end

return Deployment


