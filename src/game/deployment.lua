--[[
    Deployment system
    Select a command card and place unit cards into formation slots.
--]]

local Deployment = {}
local UnitCards = require('src.cards.unit_cards')

local chineseFont = {}
Deployment.clickAreas = {}

local cardListOffset = 0
local cardListMaxOffset = 0

local deploymentState = {
    selectedCommand = nil,
    vanguardCards = {},
    centerCards = {},
    rearCards = {},

    rowCounts = {
        vanguard = 3,
        center = 3,
        rear = 3
    },

    selectedPosition = UnitCards.POSITION.VANGUARD,
    selectedSlotIndex = 1,
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

local function loadChineseFonts()
    local fontPaths = {
        "assets/fonts/simhei.ttf",
        "assets/fonts/simkai.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/simkai.ttf",
    }

    for _, path in ipairs(fontPaths) do
        local ok = pcall(function()
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
        if ok then return true end
    end

    chineseFont[8] = love.graphics.newFont(8)
    chineseFont[9] = love.graphics.newFont(9)
    chineseFont[10] = love.graphics.newFont(10)
    chineseFont[12] = love.graphics.newFont(12)
    chineseFont[14] = love.graphics.newFont(14)
    chineseFont[16] = love.graphics.newFont(16)
    chineseFont[18] = love.graphics.newFont(18)
    chineseFont[20] = love.graphics.newFont(20)
    chineseFont[24] = love.graphics.newFont(24)
    return false
end

local function getRowTable(rowType)
    if rowType == UnitCards.POSITION.VANGUARD then
        return deploymentState.vanguardCards
    elseif rowType == UnitCards.POSITION.CENTER then
        return deploymentState.centerCards
    elseif rowType == UnitCards.POSITION.REAR then
        return deploymentState.rearCards
    end
    return nil
end

local function countCardsInRow(rowTable, maxCount)
    local count = 0
    for i = 1, maxCount do
        if rowTable[i] then count = count + 1 end
    end
    return count
end

local function findFirstAvailableSlot(rowType)
    local rowTable = getRowTable(rowType)
    local maxCount = deploymentState.rowCounts[rowType] or 1
    if not rowTable then return 1 end
    for i = 1, maxCount do
        if not rowTable[i] then return i end
    end
    return 1
end

local function getRarityColor(rarity)
    return UnitCards.getRarityColor(rarity)
end

local function drawCardSimple(card, x, y, w, h, selected)
    local rc = getRarityColor(card.rarity or "common")

    love.graphics.setColor(0.14, 0.16, 0.2, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 6)

    love.graphics.setColor(rc[1], rc[2], rc[3], selected and 1 or 0.9)
    love.graphics.setLineWidth(selected and 3 or 2)
    love.graphics.rectangle("line", x, y, w, h, 6)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(chineseFont[12])
    love.graphics.print(card.name or "Card", x + 6, y + 4)

    love.graphics.setColor(rc[1], rc[2], rc[3], 0.95)
    love.graphics.setFont(chineseFont[8])
    love.graphics.print(rarityLabel[card.rarity or "common"] or "COMMON", x + w - 58, y + 6)

    love.graphics.setColor(0.8, 0.8, 0.6)
    love.graphics.setFont(chineseFont[9])
    love.graphics.print(card.title or "", x + 6, y + 20)

    love.graphics.setColor(0.9, 0.7, 0.3)
    love.graphics.setFont(chineseFont[10])
    local stats = {}
    if card.sendPower then table.insert(stats, string.format("S:%.2f", card.sendPower)) end
    if card.recvPower then table.insert(stats, string.format("R:%.2f", card.recvPower)) end
    if card.interceptPower then table.insert(stats, string.format("I:%.2f", card.interceptPower)) end
    love.graphics.print(table.concat(stats, " "), x + 6, y + h - 18)
end

function Deployment.init(playerId)
    loadChineseFonts()

    deploymentState.playerId = playerId or 1
    deploymentState.selectedCommand = nil
    deploymentState.vanguardCards = {}
    deploymentState.centerCards = {}
    deploymentState.rearCards = {}

    deploymentState.rowCounts = {
        vanguard = 3,
        center = 3,
        rear = 3
    }

    deploymentState.selectedPosition = UnitCards.POSITION.VANGUARD
    deploymentState.selectedSlotIndex = 1

    cardListOffset = 0
    cardListMaxOffset = 0

    deploymentState.availableCards = {}
    for _, card in ipairs(UnitCards.getAll()) do
        table.insert(deploymentState.availableCards, card)
    end
end

function Deployment.addCardToRow(cardId, rowType, slotIndex)
    local card = UnitCards.createInstance(cardId, rowType)
    if not card then return false end

    if rowType == UnitCards.POSITION.COMMAND then
        deploymentState.selectedCommand = card
        return true
    end

    local rowTable = getRowTable(rowType)
    local maxCount = deploymentState.rowCounts[rowType]
    if not rowTable or slotIndex < 1 or slotIndex > maxCount then
        return false
    end

    rowTable[slotIndex] = card
    return true
end

function Deployment.autoDeploy()
    deploymentState.selectedCommand = nil
    deploymentState.vanguardCards = {}
    deploymentState.centerCards = {}
    deploymentState.rearCards = {}

    local allCards = UnitCards.getAll()
    if #allCards > 0 then
        local cmd = allCards[math.random(#allCards)]
        Deployment.addCardToRow(cmd.id, UnitCards.POSITION.COMMAND, 1)
    end

    local function fillRow(rowType)
        local maxCount = deploymentState.rowCounts[rowType]
        for i = 1, maxCount do
            local c = allCards[math.random(#allCards)]
            Deployment.addCardToRow(c.id, rowType, i)
        end
    end

    fillRow(UnitCards.POSITION.VANGUARD)
    fillRow(UnitCards.POSITION.CENTER)
    fillRow(UnitCards.POSITION.REAR)
end

function Deployment.isComplete()
    if not deploymentState.selectedCommand then return false end
    if countCardsInRow(deploymentState.vanguardCards, deploymentState.rowCounts.vanguard) == 0 then return false end
    if countCardsInRow(deploymentState.centerCards, deploymentState.rowCounts.center) == 0 then return false end
    if countCardsInRow(deploymentState.rearCards, deploymentState.rowCounts.rear) == 0 then return false end
    return true
end

function Deployment.getDeploymentResult()
    return {
        command = deploymentState.selectedCommand,
        vanguard = deploymentState.vanguardCards,
        center = deploymentState.centerCards,
        rear = deploymentState.rearCards,
        rowCounts = deploymentState.rowCounts
    }
end

function Deployment.update(dt)
end

local function drawFormationPreview(screenWidth, screenHeight)
    local startX = 20
    local startY = 50
    local cardW = 90
    local cardH = 120
    local gap = 6

    -- command
    local cmdSelected = deploymentState.selectedPosition == UnitCards.POSITION.COMMAND
    love.graphics.setColor(1, 0.9, 0.5)
    love.graphics.setFont(chineseFont[16])
    love.graphics.print("Command" .. (cmdSelected and " <-" or ""), startX, startY)

    local commandY = startY + 18
    if deploymentState.selectedCommand then
        drawCardSimple(deploymentState.selectedCommand, startX, commandY, cardW, cardH, cmdSelected)
    else
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", startX, commandY, cardW, cardH, 5)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setFont(chineseFont[12])
        love.graphics.print("Select", startX + 22, commandY + 48)
    end

    table.insert(Deployment.clickAreas, {
        type = "slot", rowType = UnitCards.POSITION.COMMAND, index = 1,
        x = startX, y = commandY, width = cardW, height = cardH
    })

    local rows = {
        { key = "vanguard", name = "Vanguard", type = UnitCards.POSITION.VANGUARD, cards = deploymentState.vanguardCards, y = startY + 140 },
        { key = "center", name = "Center", type = UnitCards.POSITION.CENTER, cards = deploymentState.centerCards, y = startY + 280 },
        { key = "rear", name = "Rear", type = UnitCards.POSITION.REAR, cards = deploymentState.rearCards, y = startY + 420 }
    }

    for _, row in ipairs(rows) do
        local count = deploymentState.rowCounts[row.key]
        local selectedRow = deploymentState.selectedPosition == row.type

        local currentCount = countCardsInRow(row.cards, count)
        love.graphics.setColor(selectedRow and 1 or 0.9, selectedRow and 0.9 or 0.7, selectedRow and 0.5 or 0.3)
        love.graphics.setFont(chineseFont[16])
        love.graphics.print(string.format("%s (%d/%d)", row.name, currentCount, count), startX, row.y)

        -- +/-
        local bx, by = startX + 150, row.y
        local bw, bh = 25, 25
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.rectangle("fill", bx, by, bw, bh, 3)
        love.graphics.rectangle("fill", bx + bw + 5, by, bw, bh, 3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(chineseFont[18])
        love.graphics.print("-", bx + 8, by + 2)
        love.graphics.print("+", bx + bw + 10, by + 2)

        table.insert(Deployment.clickAreas, { type = "adjustCount", rowKey = row.key, delta = -1, x = bx, y = by, width = bw, height = bh })
        table.insert(Deployment.clickAreas, { type = "adjustCount", rowKey = row.key, delta = 1, x = bx + bw + 5, y = by, width = bw, height = bh })

        for i = 1, count do
            local x = startX + (i - 1) * (cardW + gap)
            local y = row.y + 18
            local slotSelected = selectedRow and deploymentState.selectedSlotIndex == i

            if row.cards[i] then
                drawCardSimple(row.cards[i], x, y, cardW, cardH, slotSelected)
            else
                love.graphics.setColor(slotSelected and 0.3 or 0.15, slotSelected and 0.3 or 0.15, slotSelected and 0.35 or 0.2)
                love.graphics.rectangle("fill", x, y, cardW, cardH, 5)
                love.graphics.setColor(slotSelected and 1 or 0.3, slotSelected and 0.8 or 0.3, slotSelected and 0.2 or 0.35)
                love.graphics.rectangle("line", x, y, cardW, cardH, 5)
                love.graphics.setFont(chineseFont[18])
                love.graphics.print(slotSelected and "+" or "-", x + 38, y + 48)
            end

            table.insert(Deployment.clickAreas, {
                type = "slot", rowType = row.type, index = i,
                x = x, y = y, width = cardW, height = cardH
            })
        end
    end
end

local function drawCardSelection(screenWidth, screenHeight)
    local panelX = screenWidth - 320
    local panelY = 80
    local panelWidth = 300
    local panelHeight = screenHeight - 160

    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)

    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[16])
    love.graphics.print("Cards (Wheel Scroll)", panelX + 10, panelY + 8)

    local cardHeight = 56
    local cardGap = 6
    local totalCardHeight = cardHeight + cardGap
    local visibleHeight = panelHeight - 50
    local totalHeight = #deploymentState.availableCards * totalCardHeight
    cardListMaxOffset = math.max(0, totalHeight - visibleHeight)

    love.graphics.setScissor(panelX, panelY + 30, panelWidth, panelHeight - 30)

    table.sort(deploymentState.availableCards, function(a, b)
        local ar = rarityOrder[a.rarity or "common"] or 1
        local br = rarityOrder[b.rarity or "common"] or 1
        if ar == br then return (a.name or "") < (b.name or "") end
        return ar > br
    end)

    local startY = panelY + 40 - cardListOffset
    for i, card in ipairs(deploymentState.availableCards) do
        local y = startY + (i - 1) * totalCardHeight
        if y + cardHeight >= panelY + 30 and y <= panelY + panelHeight - 10 then
            local rc = getRarityColor(card.rarity or "common")
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", panelX + 10, y, panelWidth - 20, cardHeight, 3)
            love.graphics.setColor(rc[1], rc[2], rc[3])
            love.graphics.rectangle("line", panelX + 10, y, panelWidth - 20, cardHeight, 3)

            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(chineseFont[12])
            love.graphics.print(card.name, panelX + 15, y + 4)

            love.graphics.setColor(rc[1], rc[2], rc[3])
            love.graphics.setFont(chineseFont[8])
            love.graphics.print(rarityLabel[card.rarity or "common"] or "COMMON", panelX + panelWidth - 90, y + 4)

            love.graphics.setColor(0.8, 0.8, 0.6)
            love.graphics.setFont(chineseFont[9])
            love.graphics.print(card.title or "", panelX + 15, y + 18)

            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.setFont(chineseFont[8])
            love.graphics.printf(card.description or "", panelX + 15, y + 32, panelWidth - 30, "left")

            table.insert(Deployment.clickAreas, {
                type = "card", cardId = card.id,
                x = panelX + 10, y = y, width = panelWidth - 20, height = cardHeight
            })
        end
    end

    love.graphics.setScissor()

    if cardListMaxOffset > 0 then
        local scrollbarHeight = visibleHeight * (visibleHeight / totalHeight)
        local scrollbarY = panelY + 30 + (cardListOffset / cardListMaxOffset) * (visibleHeight - scrollbarHeight)
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.rectangle("fill", panelX + panelWidth - 8, scrollbarY, 6, scrollbarHeight, 3)
    end
end

local function drawButtons(screenWidth, screenHeight)
    local buttons = {
        {
            text = "Auto",
            x = screenWidth - 320, y = screenHeight - 70, width = 90, height = 40,
            enabled = true,
            onClick = function() Deployment.autoDeploy() end
        },
        {
            text = "Clear",
            x = screenWidth - 220, y = screenHeight - 70, width = 70, height = 40,
            enabled = true,
            onClick = function()
                deploymentState.selectedCommand = nil
                deploymentState.vanguardCards = {}
                deploymentState.centerCards = {}
                deploymentState.rearCards = {}
            end
        },
        {
            text = "Confirm",
            x = screenWidth - 140, y = screenHeight - 70, width = 120, height = 40,
            enabled = Deployment.isComplete(),
            onClick = function()
                if not Deployment.isComplete() then return end
                local deploymentResult = Deployment.getDeploymentResult()
                local Battle = require('src.game.battle')
                Battle.setDeploymentData({ player1 = deploymentResult, player2 = nil })
                local GameState = require('src.game.gamestate')
                GameState.switch("game")
            end
        }
    }

    love.graphics.setFont(chineseFont[16])
    local mx, my = love.mouse.getPosition()
    for _, btn in ipairs(buttons) do
        local hovered = mx >= btn.x and mx <= btn.x + btn.width and my >= btn.y and my <= btn.y + btn.height
        if btn.enabled == false then
            love.graphics.setColor(0.3, 0.3, 0.3)
        elseif hovered then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.3, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5)
        love.graphics.setColor(0.6, 0.7, 0.8)
        love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5)

        love.graphics.setColor(btn.enabled == false and 0.5 or 1, 1, 1)
        local tw = (chineseFont[16]):getWidth(btn.text)
        love.graphics.print(btn.text, btn.x + (btn.width - tw) / 2, btn.y + 10)

        table.insert(Deployment.clickAreas, {
            type = "button", onClick = btn.onClick, enabled = btn.enabled ~= false,
            x = btn.x, y = btn.y, width = btn.width, height = btn.height
        })
    end
end

local function drawInfo(screenWidth, screenHeight)
    if Deployment.isComplete() then return end

    love.graphics.setColor(0.9, 0.5, 0.3)
    love.graphics.setFont(chineseFont[14])

    local messages = {}
    if not deploymentState.selectedCommand then table.insert(messages, "Select a command card") end
    if countCardsInRow(deploymentState.vanguardCards, deploymentState.rowCounts.vanguard) == 0 then table.insert(messages, "Vanguard needs at least 1 unit") end
    if countCardsInRow(deploymentState.centerCards, deploymentState.rowCounts.center) == 0 then table.insert(messages, "Center needs at least 1 unit") end
    if countCardsInRow(deploymentState.rearCards, deploymentState.rowCounts.rear) == 0 then table.insert(messages, "Rear needs at least 1 unit") end

    for i, msg in ipairs(messages) do
        love.graphics.print(msg, 20, screenHeight - 30 - (#messages - i) * 20)
    end
end

function Deployment.draw()
    Deployment.clickAreas = {}

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    love.graphics.setColor(0.07, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setColor(0.16, 0.12, 0.08, 0.25)
    love.graphics.rectangle("fill", 0, 0, screenWidth, 80)

    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[24])
    love.graphics.print("Deployment", 20, 20)

    drawFormationPreview(screenWidth, screenHeight)
    drawCardSelection(screenWidth, screenHeight)
    drawButtons(screenWidth, screenHeight)
    drawInfo(screenWidth, screenHeight)
end

function Deployment.handleClick(x, y)
    if not Deployment.clickAreas then return false end

    local function placeCard(cardId)
        local rowType = deploymentState.selectedPosition or UnitCards.POSITION.VANGUARD
        local slotIndex = deploymentState.selectedSlotIndex or 1

        local ok = Deployment.addCardToRow(cardId, rowType, slotIndex)
        if ok then return true end

        if rowType ~= UnitCards.POSITION.COMMAND then
            local fallback = findFirstAvailableSlot(rowType)
            ok = Deployment.addCardToRow(cardId, rowType, fallback)
            if ok then
                deploymentState.selectedSlotIndex = fallback
                return true
            end
        end

        return false
    end

    for i = #Deployment.clickAreas, 1, -1 do
        local area = Deployment.clickAreas[i]
        if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
            if area.type == "card" then
                return placeCard(area.cardId)
            elseif area.type == "slot" then
                local prevRow = deploymentState.selectedPosition
                local prevIdx = deploymentState.selectedSlotIndex

                deploymentState.selectedPosition = area.rowType
                deploymentState.selectedSlotIndex = area.index

                if area.rowType == UnitCards.POSITION.COMMAND then
                    if deploymentState.selectedCommand and prevRow == area.rowType and prevIdx == area.index then
                        deploymentState.selectedCommand = nil
                    end
                    return true
                end

                local rowTable = getRowTable(area.rowType)
                if rowTable and rowTable[area.index] and prevRow == area.rowType and prevIdx == area.index then
                    rowTable[area.index] = nil
                end
                return true
            elseif area.type == "adjustCount" then
                local currentCount = deploymentState.rowCounts[area.rowKey]
                local newCount = math.max(1, math.min(5, currentCount + area.delta))
                deploymentState.rowCounts[area.rowKey] = newCount

                local rowType = area.rowKey == "vanguard" and UnitCards.POSITION.VANGUARD
                    or area.rowKey == "center" and UnitCards.POSITION.CENTER
                    or UnitCards.POSITION.REAR
                local rowTable = getRowTable(rowType)
                while #rowTable > newCount do
                    table.remove(rowTable)
                end
                if deploymentState.selectedPosition == rowType then
                    deploymentState.selectedSlotIndex = math.min(deploymentState.selectedSlotIndex, newCount)
                end
                return true
            elseif area.type == "button" then
                if area.enabled and area.onClick then area.onClick() end
                return true
            end
        end
    end

    return false
end

function Deployment.mousepressed(x, y, button)
    if button ~= 1 then return end
    Deployment.handleClick(x, y)
end

function Deployment.wheelmoved(x, y)
    local panelX = love.graphics.getWidth() - 320
    local panelY = 80
    local panelWidth = 300
    local panelHeight = love.graphics.getHeight() - 160

    local mx, my = love.mouse.getPosition()
    if mx >= panelX and mx <= panelX + panelWidth and my >= panelY and my <= panelY + panelHeight then
        cardListOffset = cardListOffset - y * 30
        cardListOffset = math.max(0, math.min(cardListMaxOffset, cardListOffset))
    end
end

return Deployment
