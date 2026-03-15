--[[
    Deployment system
    Select a command card and place unit cards into formation slots.
--]]

local Deployment = {}
local UnitCards = require('src.cards.unit_cards')
local CardRenderer = require('src.cards.card_renderer')

local chineseFont = {}
local backgroundImage = nil
local buttonImgs = {}
local slotImg = nil
local cardBorderImg = nil
local cardSlotMaterialImg = nil
local listPanelBgImage = nil
Deployment.clickAreas = {}

local cardListOffset = 0
local cardListMaxOffset = 0

-- Drag and drop state
local dragState = {
    isDragging = false,
    card = nil,        -- The card data being dragged
    cardX = 0,         -- Original card position X
    cardY = 0,         -- Original card position Y
    cardW = 0,         -- Card width
    cardH = 0,         -- Card height
    mouseX = 0,        -- Current mouse X
    mouseY = 0,        -- Current mouse Y
    offsetX = 0,       -- Offset from card top-left to mouse click point
    offsetY = 0
}

-- Track placed card instances (by instance id or card id + position)
local placedCardIds = {}  -- Set of card ids that are currently placed

-- Base resolution for scaling calculations
local BASE_WIDTH = 1920
local BASE_HEIGHT = 1080

local function getScale()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    return math.min(screenWidth / BASE_WIDTH, screenHeight / BASE_HEIGHT)
end

local function getScaledValue(baseValue)
    return baseValue * getScale()
end

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

-- Update the set of placed card IDs
local function updatePlacedCardIds()
    placedCardIds = {}

    -- Check command slot
    if deploymentState.selectedCommand and deploymentState.selectedCommand.id then
        placedCardIds[deploymentState.selectedCommand.id] = true
    end

    -- Check vanguard, center, rear rows
    -- Use numeric loop to handle nil gaps in arrays
    for _, rowKey in ipairs({"vanguard", "center", "rear"}) do
        local rowCards = getRowTable(rowKey == "vanguard" and UnitCards.POSITION.VANGUARD
            or rowKey == "center" and UnitCards.POSITION.CENTER
            or UnitCards.POSITION.REAR)
        local maxCount = deploymentState.rowCounts[rowKey] or 3
        if rowCards then
            for i = 1, maxCount do
                local card = rowCards[i]
                if card and card.id then
                    placedCardIds[card.id] = true
                end
            end
        end
    end
end

-- Check if a card (by id) is already placed
local function isCardPlaced(cardId)
    return placedCardIds[cardId] == true
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
    -- Use FIFA/NBA2K style card renderer
    CardRenderer.drawCard(card, x, y, w, h, {
        selected = selected,
        time = love.timer.getTime()
    })
end

local function drawSlot(x, y, w, h, selected, scale, isEmpty)
    scale = scale or 1
    isEmpty = isEmpty ~= false  -- Default to true if not specified

    -- Draw card border (always visible to mark slot position)
    if cardBorderImg then
        local imgW, imgH = cardBorderImg:getWidth(), cardBorderImg:getHeight()
        local scaleX = w / imgW
        local scaleY = h / imgH
        local imgScale = math.min(scaleX, scaleY)
        local drawW, drawH = imgW * imgScale, imgH * imgScale
        local drawX = x + (w - drawW) / 2
        local drawY = y + (h - drawH) / 2
        love.graphics.setColor(1, 1, 1, selected and 1 or 0.85)
        love.graphics.draw(cardBorderImg, drawX, drawY, 0, imgScale, imgScale)
    else
        -- Fallback: draw a simple border rectangle
        love.graphics.setColor(selected and 1 or 0.3, selected and 0.8 or 0.3, selected and 0.2 or 0.35)
        love.graphics.rectangle("line", x, y, w, h, 5 * scale)
    end

    -- Draw slot material only when slot is empty
    if isEmpty and cardSlotMaterialImg then
        local imgW, imgH = cardSlotMaterialImg:getWidth(), cardSlotMaterialImg:getHeight()
        local scaleX = w / imgW
        local scaleY = h / imgH
        local imgScale = math.min(scaleX, scaleY) * 0.9  -- Slightly smaller than border
        local drawW, drawH = imgW * imgScale, imgH * imgScale
        local drawX = x + (w - drawW) / 2
        local drawY = y + (h - drawH) / 2
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.draw(cardSlotMaterialImg, drawX, drawY, 0, imgScale, imgScale)
    elseif isEmpty and not cardSlotMaterialImg then
        -- Fallback: draw placeholder text when empty
        love.graphics.setColor(selected and 0.6 or 0.4, selected and 0.6 or 0.4, selected and 0.6 or 0.4)
        love.graphics.setFont(chineseFont[18] or love.graphics.newFont(18))
        local placeholderSize = "+"
        local font = chineseFont[18] or love.graphics.newFont(18)
        local tw = font:getWidth(placeholderSize)
        love.graphics.print(placeholderSize, x + w / 2 - tw / 2, y + h / 2 - 9 * scale)
    end
end

function Deployment.init(playerId)
    loadChineseFonts()

    -- Initialize card renderer
    CardRenderer.init()

    -- Load background image
    local ok, img = pcall(love.graphics.newImage, "assets/images/backgrounds/bg_deployment.png")
    if ok and img then
        backgroundImage = img
        backgroundImage:setFilter("linear", "linear")
    end

    -- Load button images
    for i = 1, 3 do
        local okBtn, imgBtn = pcall(love.graphics.newImage, string.format("assets/images/backgrounds/button%d.png", i))
        if okBtn and imgBtn then
            buttonImgs[i] = imgBtn
            buttonImgs[i]:setFilter("linear", "linear")
        end
    end

    -- Load slot image
    local okSlot, imgSlot = pcall(love.graphics.newImage, "assets/images/backgrounds/slot.png")
    if okSlot and imgSlot then
        slotImg = imgSlot
        slotImg:setFilter("linear", "linear")
    end

    -- Load new card border and slot material images
    local okBorder, imgBorder = pcall(love.graphics.newImage, "assets/cards/backgrounds/card_border.png")
    if okBorder and imgBorder then
        cardBorderImg = imgBorder
        cardBorderImg:setFilter("linear", "linear")
    end

    local okMaterial, imgMaterial = pcall(love.graphics.newImage, "assets/cards/backgrounds/card_slot_material.png")
    if okMaterial and imgMaterial then
        cardSlotMaterialImg = imgMaterial
        cardSlotMaterialImg:setFilter("linear", "linear")
    end

    -- Load list panel background image (same as cards page)
    local okListBg, imgListBg = pcall(love.graphics.newImage, "assets/images/backgrounds/card_scroll.png")
    if okListBg and imgListBg then
        listPanelBgImage = imgListBg
        listPanelBgImage:setFilter("linear", "linear")
    end

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

    -- Reset drag state
    dragState = {
        isDragging = false,
        card = nil,
        cardX = 0,
        cardY = 0,
        cardW = 0,
        cardH = 0,
        mouseX = 0,
        mouseY = 0,
        offsetX = 0,
        offsetY = 0
    }
    placedCardIds = {}

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
    if #allCards == 0 then return end

    -- Track used card IDs to avoid duplicates
    local usedIds = {}
    local function getRandomUnusedCard()
        -- Find all unused cards
        local available = {}
        for _, card in ipairs(allCards) do
            if not usedIds[card.id] then
                table.insert(available, card)
            end
        end
        if #available == 0 then return nil end
        local picked = available[math.random(#available)]
        usedIds[picked.id] = true
        return picked
    end

    -- Select command card
    local cmd = getRandomUnusedCard()
    if cmd then
        Deployment.addCardToRow(cmd.id, UnitCards.POSITION.COMMAND, 1)
    end

    -- Fill rows with non-duplicate cards
    local function fillRow(rowType)
        local maxCount = deploymentState.rowCounts[rowType]
        for i = 1, maxCount do
            local c = getRandomUnusedCard()
            if c then
                Deployment.addCardToRow(c.id, rowType, i)
            end
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
    local scale = getScale()

    -- Card dimensions - scaled by resolution, then 1.5x larger
    local baseCardW = 140
    local baseCardH = 210
    local cardW = baseCardW * scale
    local cardH = baseCardH * scale
    local gap = cardW * 0.3  -- Gap between cards in a row (0.6x card width)
    local rowGap = cardH * 0.05  -- Gap between rows (vertical)
    local titleWidth = 60 * scale  -- Fixed width for left side title

    -- Left panel (formation area) takes ~70% of screen width
    -- Cards should be centered around the center line of this area
    local formationWidth = screenWidth * 0.70
    local formationCenterX = formationWidth / 2 + titleWidth / 2  -- Adjusted for left title

    -- Calculate total height for all 4 rows
    local maxCardsPerRow = 3
    local rowHeight = cardH

    -- Starting position - centered vertically
    local totalHeight = rowHeight * 4 + rowGap * 3
    local startY = (screenHeight - totalHeight) / 2

    -- Chinese row names
    local rowNames = {
        command = "大营",
        vanguard = "前锋",
        center = "中军",
        rear = "后卫"
    }

    -- Helper function to draw a row
    local function drawRow(rowKey, rowType, rowName, cards, count, y, isCommand)
        local selectedRow = deploymentState.selectedPosition == rowType
        local currentCount = isCommand and (cards and 1 or 0) or countCardsInRow(cards, count)

        -- Calculate row width and center it
        local numSlots = isCommand and 1 or count
        local rowWidth = numSlots * cardW + (numSlots - 1) * gap
        local rowStartX = formationCenterX - rowWidth / 2

        -- Row title (fixed on the left side, vertically centered with cards)
        love.graphics.setColor(selectedRow and 1 or 0.9, selectedRow and 0.9 or 0.7, selectedRow and 0.5 or 0.3)
        love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
        local titleText = rowName
        local font = chineseFont[16] or love.graphics.newFont(16)
        local textHeight = font:getHeight()
        love.graphics.print(titleText, 15 * scale, y + (cardH - textHeight) / 2)

        -- +/- buttons for non-command rows (positioned to the right of the row)
        if not isCommand then
            local btnX = rowStartX + rowWidth + 15 * scale
            local bw, bh = 25 * scale, 25 * scale
            love.graphics.setColor(0.4, 0.4, 0.5)
            love.graphics.rectangle("fill", btnX, y, bw, bh, 3 * scale)
            love.graphics.rectangle("fill", btnX + bw + 5 * scale, y, bw, bh, 3 * scale)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(chineseFont[18] or love.graphics.newFont(18))
            love.graphics.print("-", btnX + 8 * scale, y + 2 * scale)
            love.graphics.print("+", btnX + bw + 10 * scale, y + 2 * scale)

            table.insert(Deployment.clickAreas, { type = "adjustCount", rowKey = rowKey, delta = -1, x = btnX, y = y, width = bw, height = bh })
            table.insert(Deployment.clickAreas, { type = "adjustCount", rowKey = rowKey, delta = 1, x = btnX + bw + 5 * scale, y = y, width = bw, height = bh })
        end

        -- Cards in this row (horizontal arrangement, centered)
        local cardY = y

        for i = 1, numSlots do
            local cardX = rowStartX + (i - 1) * (cardW + gap)
            local slotSelected = selectedRow and deploymentState.selectedSlotIndex == i

            local card = isCommand and deploymentState.selectedCommand or (cards and cards[i])
            local isEmpty = not card

            if card then
                drawCardSimple(card, cardX, cardY, cardW, cardH, slotSelected)
            end

            drawSlot(cardX, cardY, cardW, cardH, slotSelected, scale, isEmpty)

            table.insert(Deployment.clickAreas, {
                type = "slot", rowType = rowType, index = i,
                x = cardX, y = cardY, width = cardW, height = cardH
            })
        end
    end

    -- Row order: Vanguard (top), Center, Rear, Command (bottom)
    -- Row 1: Vanguard (前锋) - at top
    local row1Y = startY
    drawRow("vanguard", UnitCards.POSITION.VANGUARD, rowNames.vanguard, deploymentState.vanguardCards, deploymentState.rowCounts.vanguard, row1Y, false)

    -- Row 2: Center (中军)
    local row2Y = row1Y + rowHeight + rowGap
    drawRow("center", UnitCards.POSITION.CENTER, rowNames.center, deploymentState.centerCards, deploymentState.rowCounts.center, row2Y, false)

    -- Row 3: Rear (后卫)
    local row3Y = row2Y + rowHeight + rowGap
    drawRow("rear", UnitCards.POSITION.REAR, rowNames.rear, deploymentState.rearCards, deploymentState.rowCounts.rear, row3Y, false)

    -- Row 4: Command (大营) - at bottom
    local row4Y = row3Y + rowHeight + rowGap
    drawRow("command", UnitCards.POSITION.COMMAND, rowNames.command, deploymentState.selectedCommand, 1, row4Y, true)
end

local function drawCardSelection(screenWidth, screenHeight)
    local scale = getScale()

    -- Panel takes the right 30% of screen
    local panelX = screenWidth * 0.72
    local panelY = 80 * scale
    local panelWidth = screenWidth * 0.26
    local panelHeight = screenHeight - 160 * scale

    -- Sort cards by rarity
    table.sort(deploymentState.availableCards, function(a, b)
        local ar = rarityOrder[a.rarity or "common"] or 1
        local br = rarityOrder[b.rarity or "common"] or 1
        if ar == br then return (a.name or "") < (b.name or "") end
        return ar > br
    end)

    -- Grid layout: 3 cards per row
    local cols = 3
    local pad = 8 * scale
    local gapX = 6 * scale
    local gapY = 8 * scale
    local cardW = math.floor((panelWidth - pad * 2 - gapX * (cols - 1)) / cols)
    local cardH = math.floor(cardW * 1.4)

    local rows = math.ceil(#deploymentState.availableCards / cols)
    local contentHeight = rows * cardH + math.max(0, rows - 1) * gapY + pad * 2
    cardListMaxOffset = math.max(0, contentHeight - panelHeight)

    -- Clamp scroll
    cardListOffset = math.max(0, math.min(cardListMaxOffset, cardListOffset))

    -- Draw scrolling background with infinite vertical tiling (same as cards page)
    love.graphics.setScissor(panelX, panelY, panelWidth, panelHeight)
    if listPanelBgImage then
        local bgH = listPanelBgImage:getHeight()
        local bgW = listPanelBgImage:getWidth()
        local bgScale = panelWidth / bgW
        local scaledBgH = bgH * bgScale

        -- Calculate offset based on scroll (parallax effect)
        local scrollOffset = cardListOffset * 0.5
        local offsetY = scrollOffset % scaledBgH

        -- Draw tiled background
        love.graphics.setColor(1, 1, 1, 1)
        local y = panelY - offsetY
        while y < panelY + panelHeight + scaledBgH do
            love.graphics.draw(listPanelBgImage, panelX, y, 0, bgScale, bgScale)
            y = y + scaledBgH
        end
    else
        love.graphics.setColor(0.08, 0.11, 0.17, 0.95)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10 * scale)
    end

    -- Draw cards in grid
    local contentY = panelY + pad - cardListOffset
    for i, card in ipairs(deploymentState.availableCards) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = panelX + pad + col * (cardW + gapX)
        local y = contentY + row * (cardH + gapY)

        -- Only draw visible cards
        if y + cardH >= panelY and y <= panelY + panelHeight then
            local cardPlaced = isCardPlaced(card.id)

            -- Draw card using card renderer
            if cardPlaced then
                -- Draw grayed out version for placed cards
                love.graphics.setColor(0.4, 0.4, 0.4, 0.7)
                CardRenderer.drawCard(card, x, y, cardW, cardH, {
                    selected = false,
                    time = love.timer.getTime(),
                    grayed = true
                })
                -- Draw overlay to indicate already placed
                love.graphics.setColor(0, 0, 0, 0.5)
                love.graphics.rectangle("fill", x, y, cardW, cardH)
            else
                CardRenderer.drawCard(card, x, y, cardW, cardH, {
                    selected = false,
                    time = love.timer.getTime()
                })
            end

            -- Add click area (only for non-placed cards)
            if not cardPlaced then
                table.insert(Deployment.clickAreas, {
                    type = "card", cardId = card.id, card = card,
                    x = x, y = y, width = cardW, height = cardH
                })
            end
        end
    end

    love.graphics.setScissor()

    -- Draw scrollbar
    if cardListMaxOffset > 0 then
        local trackX = panelX + panelWidth - 10 * scale
        local trackH = panelHeight
        local thumbH = math.max(30 * scale, trackH * (panelHeight / (contentHeight + panelHeight)))
        local thumbY = panelY + (cardListOffset / cardListMaxOffset) * (trackH - thumbH)
        love.graphics.setColor(0.18, 0.25, 0.38, 1)
        love.graphics.rectangle("fill", trackX, panelY, 5 * scale, trackH, 3 * scale)
        love.graphics.setColor(0.46, 0.64, 0.96, 1)
        love.graphics.rectangle("fill", trackX, thumbY, 5 * scale, thumbH, 3 * scale)
    end
end

local function drawButtons(screenWidth, screenHeight)
    local scale = getScale()

    -- Use same panel dimensions as card selection for consistency
    local panelX = screenWidth * 0.72
    local panelWidth = screenWidth * 0.26

    -- Button layout: 3 buttons evenly spaced
    local btnHeight = 40 * scale
    local btnGap = 10 * scale
    local btnWidth = (panelWidth - btnGap * 2) / 3
    local btnY = screenHeight - 70 * scale

    local buttons = {
        {
            text = "Auto",
            x = panelX, y = btnY, width = btnWidth, height = btnHeight,
            enabled = true,
            imgIdx = 1,
            onClick = function() Deployment.autoDeploy() end
        },
        {
            text = "Clear",
            x = panelX + btnWidth + btnGap, y = btnY, width = btnWidth, height = btnHeight,
            enabled = true,
            imgIdx = 1,
            onClick = function()
                deploymentState.selectedCommand = nil
                deploymentState.vanguardCards = {}
                deploymentState.centerCards = {}
                deploymentState.rearCards = {}
            end
        },
        {
            text = "Confirm",
            x = panelX + (btnWidth + btnGap) * 2, y = btnY, width = btnWidth, height = btnHeight,
            enabled = Deployment.isComplete(),
            imgIdx = 1,
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

    love.graphics.setFont(chineseFont[16] or love.graphics.newFont(16))
    local mx, my = love.mouse.getPosition()
    for _, btn in ipairs(buttons) do
        local hovered = mx >= btn.x and mx <= btn.x + btn.width and my >= btn.y and my <= btn.y + btn.height

        -- Draw button with image or fallback
        local img = buttonImgs[btn.imgIdx]
        if img then
            -- Scale to fit inside button bounds (use min instead of max to ensure it fits)
            local imgW, imgH = img:getWidth(), img:getHeight()
            local imgScale = math.min(btn.width / imgW, btn.height / imgH)
            local drawW, drawH = imgW * imgScale, imgH * imgScale
            -- Center the image within the button bounds
            local drawX = btn.x + (btn.width - drawW) / 2
            local drawY = btn.y + (btn.height - drawH) / 2
            local alpha = btn.enabled == false and 0.5 or (hovered and 1 or 0.85)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(img, drawX, drawY, 0, imgScale, imgScale)
        else
            if btn.enabled == false then
                love.graphics.setColor(0.3, 0.3, 0.3)
            elseif hovered then
                love.graphics.setColor(0.4, 0.6, 0.8)
            else
                love.graphics.setColor(0.3, 0.4, 0.5)
            end
            love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5 * scale)
            love.graphics.setColor(0.6, 0.7, 0.8)
            love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5 * scale)
        end

        love.graphics.setColor(btn.enabled == false and 0.5 or 1, 1, 1)
        local font = chineseFont[16] or love.graphics.newFont(16)
        local tw = font:getWidth(btn.text)
        love.graphics.print(btn.text, btn.x + (btn.width - tw) / 2, btn.y + (btn.height - 16 * scale) / 2)

        table.insert(Deployment.clickAreas, {
            type = "button", onClick = btn.onClick, enabled = btn.enabled ~= false,
            x = btn.x, y = btn.y, width = btn.width, height = btn.height
        })
    end
end

local function drawInfo(screenWidth, screenHeight)
    if Deployment.isComplete() then return end

    local scale = getScale()

    love.graphics.setColor(0.9, 0.5, 0.3)
    love.graphics.setFont(chineseFont[14] or love.graphics.newFont(14))

    local messages = {}
    if not deploymentState.selectedCommand then table.insert(messages, "Select a command card") end
    if countCardsInRow(deploymentState.vanguardCards, deploymentState.rowCounts.vanguard) == 0 then table.insert(messages, "Vanguard needs at least 1 unit") end
    if countCardsInRow(deploymentState.centerCards, deploymentState.rowCounts.center) == 0 then table.insert(messages, "Center needs at least 1 unit") end
    if countCardsInRow(deploymentState.rearCards, deploymentState.rowCounts.rear) == 0 then table.insert(messages, "Rear needs at least 1 unit") end

    for i, msg in ipairs(messages) do
        love.graphics.print(msg, 20 * scale, screenHeight - 30 * scale - (#messages - i) * 20 * scale)
    end
end

function Deployment.draw()
    Deployment.clickAreas = {}

    -- Update placed card IDs for tracking
    updatePlacedCardIds()

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
        love.graphics.setColor(0.07, 0.08, 0.12)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    end
    love.graphics.setColor(0.16, 0.12, 0.08, 0.25)
    love.graphics.rectangle("fill", 0, 0, screenWidth, 80 * scale)

    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[24] or love.graphics.newFont(24))
    love.graphics.print("Deployment", 20 * scale, 20 * scale)

    drawFormationPreview(screenWidth, screenHeight)
    drawCardSelection(screenWidth, screenHeight)
    drawButtons(screenWidth, screenHeight)
    drawInfo(screenWidth, screenHeight)

    -- Draw dragged card following mouse
    if dragState.isDragging and dragState.card then
        local dragX = dragState.mouseX - dragState.offsetX
        local dragY = dragState.mouseY - dragState.offsetY
        love.graphics.setColor(1, 1, 1, 0.9)
        CardRenderer.drawCard(dragState.card, dragX, dragY, dragState.cardW, dragState.cardH, {
            selected = true,
            time = love.timer.getTime()
        })
    end
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

    -- First check buttons (they have higher priority)
    for _, area in ipairs(Deployment.clickAreas) do
        if area.type == "button" and area.enabled then
            if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
                if area.onClick then area.onClick() end
                return true
            end
        end
    end

    -- Then check if clicking on an available card (not placed)
    for _, area in ipairs(Deployment.clickAreas) do
        if area.type == "card" and area.card then
            if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
                -- Start dragging this card
                dragState.isDragging = true
                dragState.card = area.card
                dragState.cardX = area.x
                dragState.cardY = area.y
                dragState.cardW = area.width
                dragState.cardH = area.height
                dragState.mouseX = x
                dragState.mouseY = y
                dragState.offsetX = x - area.x
                dragState.offsetY = y - area.y
                return true
            end
        end
    end

    -- Handle other clicks (slots, adjustCount, etc.)
    Deployment.handleClick(x, y)
end

function Deployment.mousemoved(x, y, dx, dy)
    if dragState.isDragging then
        dragState.mouseX = x
        dragState.mouseY = y
    end
end

function Deployment.mousereleased(x, y, button)
    if button ~= 1 then return end

    if dragState.isDragging and dragState.card then
        -- Check if dropped on a valid slot
        local droppedOnSlot = nil

        for _, area in ipairs(Deployment.clickAreas) do
            if area.type == "slot" then
                if x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height then
                    droppedOnSlot = area
                    break
                end
            end
        end

        if droppedOnSlot then
            -- Place card in the slot
            local cardId = dragState.card.id
            local rowType = droppedOnSlot.rowType
            local slotIndex = droppedOnSlot.index

            -- For command slot, only allow if empty
            if rowType == UnitCards.POSITION.COMMAND then
                if not deploymentState.selectedCommand then
                    Deployment.addCardToRow(cardId, rowType, 1)
                end
            else
                -- For other rows, place in the specific slot if empty
                local rowTable = getRowTable(rowType)
                if rowTable and not rowTable[slotIndex] then
                    Deployment.addCardToRow(cardId, rowType, slotIndex)
                end
            end
        end

        -- Reset drag state
        dragState.isDragging = false
        dragState.card = nil
        return true
    end
end

function Deployment.wheelmoved(x, y)
    -- Don't scroll while dragging a card
    if dragState.isDragging then return end

    local scale = getScale()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local panelX = screenWidth * 0.72
    local panelY = 80 * scale
    local panelWidth = screenWidth * 0.26
    local panelHeight = screenHeight - 160 * scale

    local mx, my = love.mouse.getPosition()
    if mx >= panelX and mx <= panelX + panelWidth and my >= panelY and my <= panelY + panelHeight then
        cardListOffset = cardListOffset - y * 40 * scale
        cardListOffset = math.max(0, math.min(cardListMaxOffset, cardListOffset))
    end
end

return Deployment
