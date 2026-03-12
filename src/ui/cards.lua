local Cards = {}

local UnitCards = require('src.cards.unit_cards')

local fonts = {}
local images = {}
local allCards = {}

local selectedIndex = 1
local listScroll = 0
local listMaxScroll = 0
local clickAreas = {}

local listPanel = { x = 20, y = 80, w = 0, h = 0 }

local rarityOrder = {
    common = 1,
    uncommon = 2,
    rare = 3,
    legendary = 4,
}

local rarityColor = {
    common = {0.66, 0.69, 0.75},
    uncommon = {0.36, 0.80, 0.46},
    rare = {0.37, 0.55, 0.95},
    legendary = {0.98, 0.75, 0.33},
}

local function getRarityColor(rarity)
    return rarityColor[rarity] or rarityColor.common
end

local function getFont(size)
    if fonts[size] then return fonts[size] end
    local fontPaths = {
        "assets/fonts/simhei.ttf",
        "assets/fonts/simkai.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/simkai.ttf",
        "C:/Windows/Fonts/msyh.ttc",
        "C:/Windows/Fonts/simsun.ttc",
    }
    for _, path in ipairs(fontPaths) do
        local ok, f = pcall(love.graphics.newFont, path, size)
        if ok and f then
            fonts[size] = f
            return f
        end
    end
    fonts[size] = love.graphics.newFont(size)
    return fonts[size]
end

local function safeLoadImage(path)
    local ok, img = pcall(love.graphics.newImage, path)
    if ok and img then
        img:setFilter("linear", "linear")
        return img
    end
    return nil
end

local function drawImageInRect(img, x, y, w, h, alpha)
    if not img then return end
    local a = alpha or 1
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.draw(img, x, y, 0, w / img:getWidth(), h / img:getHeight())
end

local function drawImageAtScale(img, x, y, scale, alpha)
    if not img then return end
    local s = scale or 1
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(img, x, y, 0, s, s)
end

local function hashCardId(cardId)
    local h = 0
    for i = 1, #cardId do
        h = (h + string.byte(cardId, i) * i) % 997
    end
    return h
end

local function pickPortrait(card)
    local key = hashCardId(card.id or "card") % 3
    if key == 0 then return images.portrait_warrior end
    if key == 1 then return images.portrait_strategist end
    return images.portrait_guardian
end

local function getFrameByRarity(rarity)
    return images["frame_" .. (rarity or "common")] or images.frame_common
end

local function getBadgeByRarity(rarity)
    return images["badge_" .. (rarity or "common")] or images.badge_common
end

local function calcRating(card)
    local command = card.positionEffects and card.positionEffects.command or {}
    local attack = (card.positionEffects and card.positionEffects.vanguard and card.positionEffects.vanguard.attack) or 0
    local defense = (card.positionEffects and card.positionEffects.center and card.positionEffects.center.defense) or 0
    local hp = command.hp or 30
    local rarityBoost = (rarityOrder[card.rarity] or 1) * 4
    return math.floor(40 + attack * 6 + defense * 5 + hp * 0.35 + rarityBoost)
end

local function drawStatBadge(icon, label, value, x, y, w, h)
    love.graphics.setColor(0.10, 0.14, 0.22, 1)
    love.graphics.rectangle("fill", x, y, w, h, 8)
    love.graphics.setColor(0.22, 0.30, 0.44, 1)
    love.graphics.rectangle("line", x, y, w, h, 8)

    if icon then
        drawImageInRect(icon, x + 8, y + 6, h - 12, h - 12, 0.95)
    end

    love.graphics.setColor(0.84, 0.90, 1.00, 1)
    love.graphics.setFont(getFont(12))
    love.graphics.print(label, x + h, y + 7)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(getFont(16))
    love.graphics.print(tostring(value), x + w - 22, y + 6)
end

local function drawLayeredCard(card, x, y, w, h, selected)
    local rc = getRarityColor(card.rarity)
    local frame = getFrameByRarity(card.rarity)
    local portrait = pickPortrait(card)
    local badge = getBadgeByRarity(card.rarity)
    local rating = calcRating(card)

    love.graphics.setColor(0.07, 0.09, 0.14, 0.96)
    love.graphics.rectangle("fill", x, y, w, h, 14)

    drawImageInRect(images.bg_canvas, x + 4, y + 4, w - 8, h - 8, 0.95)

    -- Portrait layer rule:
    -- size is 0.7x of displayed bg_canvas area, keep aspect ratio, place near top-right.
    love.graphics.setScissor(x + 4, y + 4, w - 8, h - 8)
    local bgW = w - 8
    local bgH = h - 8
    local targetW = bgW * 0.7
    local targetH = bgH * 0.7
    local portraitScale = 1
    if portrait then
        portraitScale = math.min(targetW / portrait:getWidth(), targetH / portrait:getHeight())
    end
    local portraitW = portrait and (portrait:getWidth() * portraitScale) or 0
    local portraitH = portrait and (portrait:getHeight() * portraitScale) or 0
    local portraitX = x + w - portraitW - 42
    local portraitY = y + 48
    drawImageAtScale(portrait, portraitX, portraitY, portraitScale, 0.96)
    love.graphics.setScissor()

    drawImageInRect(images.overlay_gloss, x + 4, y + 4, w - 8, h - 8, 0.9)
    drawImageInRect(frame, x + 1, y + 1, w - 2, h - 2, 1)
    drawImageInRect(badge, x + w - 52, y + 8, 44, 44, 1)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(getFont(14))
    love.graphics.print(card.name or "Unknown", x + 14, y + 14)

    love.graphics.setColor(0.82, 0.86, 0.96, 1)
    love.graphics.setFont(getFont(10))
    love.graphics.print(card.title or "", x + 14, y + 33)

    love.graphics.setColor(0.98, 0.92, 0.72, 1)
    love.graphics.setFont(getFont(28))
    love.graphics.print(tostring(rating), x + 14, y + 52)

    local command = card.positionEffects and card.positionEffects.command or {}
    local vanguard = card.positionEffects and card.positionEffects.vanguard or {}
    local center = card.positionEffects and card.positionEffects.center or {}
    local hp = command.hp or 30
    local attack = vanguard.attack or 0
    local defense = center.defense or 0
    local rear = card.positionEffects and card.positionEffects.rear or {}
    local rearAtk = rear.attack or 0
    local rearDef = rear.defense or 0
    local centerAtk = center.attack or 0

    -- Opaque ability zone: fully cover bottom 30% of card.
    local panelY = y + h * 0.7
    local panelH = h * 0.3
    if images.panel_stats_bg then
        drawImageInRect(images.panel_stats_bg, x + 4, panelY, w - 8, panelH - 4, 1)
    else
        love.graphics.setColor(0.05, 0.08, 0.13, 1)
        love.graphics.rectangle("fill", x + 4, panelY, w - 8, panelH - 4, 10)
    end
    love.graphics.setColor(rc[1] * 0.7, rc[2] * 0.7, rc[3] * 0.7, 1)
    love.graphics.rectangle("line", x + 4, panelY, w - 8, panelH - 4, 10)

    local titleY = panelY + 8
    love.graphics.setColor(0.90, 0.94, 1.00, 1)
    love.graphics.setFont(getFont(11))
    love.graphics.print("ABILITY VALUES", x + 12, titleY)

    local statPad = 10
    local statGap = 4
    local statW = (w - statPad * 2 - statGap * 2) / 3
    local statH = math.floor((panelH - 34 - 4) / 2)
    statH = math.max(18, math.min(34, statH))
    local row1Y = panelY + 24
    local row2Y = row1Y + statH + 4
    local col1X = x + statPad
    local col2X = col1X + statW + statGap
    local col3X = col2X + statW + statGap
    drawStatBadge(images.icon_attack, "ATK", attack, col1X, row1Y, statW, statH)
    drawStatBadge(images.icon_defense, "DEF", defense, col2X, row1Y, statW, statH)
    drawStatBadge(images.icon_power, "HP", hp, col3X, row1Y, statW, statH)
    drawStatBadge(images.icon_attack, "CTR", centerAtk, col1X, row2Y, statW, statH)
    drawStatBadge(images.icon_defense, "R-ATK", rearAtk, col2X, row2Y, statW, statH)
    drawStatBadge(images.icon_power, "R-DEF", rearDef, col3X, row2Y, statW, statH)

    love.graphics.setColor(rc[1], rc[2], rc[3], selected and 1 or 0.92)
    love.graphics.setLineWidth(selected and 3 or 2)
    love.graphics.rectangle("line", x, y, w, h, 14)
    love.graphics.setLineWidth(1)
end

local function sortCards()
    table.sort(allCards, function(a, b)
        local ra = rarityOrder[a.rarity or "common"] or 1
        local rb = rarityOrder[b.rarity or "common"] or 1
        if ra == rb then
            return (a.name or "") < (b.name or "")
        end
        return ra > rb
    end)
end

local function clampScroll()
    if listScroll < 0 then listScroll = 0 end
    if listScroll > listMaxScroll then listScroll = listMaxScroll end
end

local function addClickArea(area)
    table.insert(clickAreas, area)
end

local function drawTopBar(screenWidth)
    love.graphics.setColor(0.11, 0.15, 0.24, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, 64)

    love.graphics.setColor(0.92, 0.86, 0.64, 1)
    love.graphics.setFont(getFont(28))
    love.graphics.print("Card Collection", 20, 14)

    local backBtn = { x = screenWidth - 170, y = 14, w = 140, h = 36, type = "back" }
    local mx, my = love.mouse.getPosition()
    local hovered = mx >= backBtn.x and mx <= backBtn.x + backBtn.w and my >= backBtn.y and my <= backBtn.y + backBtn.h
    love.graphics.setColor(hovered and 0.34 or 0.24, hovered and 0.50 or 0.35, hovered and 0.76 or 0.55, 1)
    love.graphics.rectangle("fill", backBtn.x, backBtn.y, backBtn.w, backBtn.h, 8)
    love.graphics.setColor(0.78, 0.86, 1.00, 1)
    love.graphics.rectangle("line", backBtn.x, backBtn.y, backBtn.w, backBtn.h, 8)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(getFont(15))
    local t = "Back To Menu"
    local tw = getFont(15):getWidth(t)
    love.graphics.print(t, backBtn.x + (backBtn.w - tw) / 2, backBtn.y + 9)
    addClickArea(backBtn)
end

local function drawListPanel(screenWidth, screenHeight)
    listPanel.x = 20
    listPanel.y = 80
    listPanel.w = math.floor(screenWidth * 0.53)
    listPanel.h = screenHeight - 100

    love.graphics.setColor(0.08, 0.11, 0.17, 0.95)
    love.graphics.rectangle("fill", listPanel.x, listPanel.y, listPanel.w, listPanel.h, 10)
    love.graphics.setColor(0.22, 0.30, 0.44, 1)
    love.graphics.rectangle("line", listPanel.x, listPanel.y, listPanel.w, listPanel.h, 10)

    local pad = 14
    local cardW = 178
    local cardH = 248
    local gapX = 16
    local gapY = 16
    local cols = 2

    local contentX = listPanel.x + pad
    local contentY = listPanel.y + pad - listScroll

    local rows = math.ceil(#allCards / cols)
    local contentHeight = rows * cardH + math.max(0, rows - 1) * gapY
    listMaxScroll = math.max(0, contentHeight - (listPanel.h - pad * 2))
    clampScroll()

    love.graphics.setScissor(listPanel.x + 6, listPanel.y + 6, listPanel.w - 12, listPanel.h - 12)
    for i, card in ipairs(allCards) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = contentX + col * (cardW + gapX)
        local y = contentY + row * (cardH + gapY)
        if y + cardH >= listPanel.y and y <= listPanel.y + listPanel.h then
            drawLayeredCard(card, x, y, cardW, cardH, i == selectedIndex)
            addClickArea({ type = "card", index = i, x = x, y = y, w = cardW, h = cardH })
        end
    end
    love.graphics.setScissor()

    if listMaxScroll > 0 then
        local trackX = listPanel.x + listPanel.w - 12
        local trackY = listPanel.y + 12
        local trackH = listPanel.h - 24
        local thumbH = math.max(42, trackH * ((listPanel.h - 28) / (contentHeight + 8)))
        local thumbY = trackY + (listScroll / listMaxScroll) * (trackH - thumbH)
        love.graphics.setColor(0.18, 0.25, 0.38, 1)
        love.graphics.rectangle("fill", trackX, trackY, 5, trackH, 3)
        love.graphics.setColor(0.46, 0.64, 0.96, 1)
        love.graphics.rectangle("fill", trackX, thumbY, 5, thumbH, 3)
    end
end

local function drawDetailPanel(screenWidth, screenHeight)
    local x = math.floor(screenWidth * 0.56)
    local y = 80
    local w = screenWidth - x - 20
    local h = screenHeight - 100

    love.graphics.setColor(0.08, 0.10, 0.15, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 10)
    love.graphics.setColor(0.23, 0.30, 0.44, 1)
    love.graphics.rectangle("line", x, y, w, h, 10)

    local card = allCards[selectedIndex]
    if not card then return end

    local cardW = math.min(340, w - 26)
    local cardH = math.floor(cardW * 1.42)
    local cardX = x + math.floor((w - cardW) / 2)
    local cardY = y + 18
    drawLayeredCard(card, cardX, cardY, cardW, cardH, true)

    love.graphics.setColor(0.85, 0.89, 0.97, 1)
    love.graphics.setFont(getFont(13))
    local desc = card.description or "No description"
    local textY = cardY + cardH + 10
    love.graphics.printf(desc, x + 14, textY, w - 28, "left")

    local replacePath = "assets/cards/placeholders/"
    love.graphics.setColor(0.72, 0.78, 0.92, 0.92)
    love.graphics.setFont(getFont(12))
    love.graphics.printf("Placeholder assets path: " .. replacePath, x + 14, y + h - 30, w - 28, "left")
end

function Cards.init()
    allCards = {}
    for _, card in ipairs(UnitCards.getAll()) do
        table.insert(allCards, card)
    end
    sortCards()
    selectedIndex = 1
    listScroll = 0
    listMaxScroll = 0
    clickAreas = {}

    images.bg_canvas = safeLoadImage("assets/cards/placeholders/bg_canvas.png")
    images.overlay_gloss = safeLoadImage("assets/cards/placeholders/overlay_gloss.png")
    images.frame_common = safeLoadImage("assets/cards/placeholders/frame_common.png")
    images.frame_uncommon = safeLoadImage("assets/cards/placeholders/frame_uncommon.png")
    images.frame_rare = safeLoadImage("assets/cards/placeholders/frame_rare.png")
    images.frame_legendary = safeLoadImage("assets/cards/placeholders/frame_legendary.png")
    images.portrait_warrior = safeLoadImage("assets/cards/placeholders/portrait_warrior.png")
    images.portrait_strategist = safeLoadImage("assets/cards/placeholders/portrait_strategist.png")
    images.portrait_guardian = safeLoadImage("assets/cards/placeholders/portrait_guardian.png")
    images.badge_common = safeLoadImage("assets/cards/placeholders/badge_common.png")
    images.badge_uncommon = safeLoadImage("assets/cards/placeholders/badge_uncommon.png")
    images.badge_rare = safeLoadImage("assets/cards/placeholders/badge_rare.png")
    images.badge_legendary = safeLoadImage("assets/cards/placeholders/badge_legendary.png")
    images.icon_attack = safeLoadImage("assets/cards/placeholders/icon_attack.png")
    images.icon_defense = safeLoadImage("assets/cards/placeholders/icon_defense.png")
    images.icon_power = safeLoadImage("assets/cards/placeholders/icon_power.png")
    images.panel_stats_bg = safeLoadImage("assets/cards/placeholders/panel_stats_bg.png")
end

function Cards.update(dt)
end

function Cards.draw()
    clickAreas = {}

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    love.graphics.setColor(0.04, 0.06, 0.10, 1)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    drawTopBar(sw)
    drawListPanel(sw, sh)
    drawDetailPanel(sw, sh)
end

function Cards.mousepressed(x, y, button)
    if button ~= 1 then return end
    for i = #clickAreas, 1, -1 do
        local a = clickAreas[i]
        if x >= a.x and x <= a.x + a.w and y >= a.y and y <= a.y + a.h then
            if a.type == "card" then
                selectedIndex = a.index
                return
            elseif a.type == "back" then
                local GameState = require('src.game.gamestate')
                GameState.switch("menu")
                return
            end
        end
    end
end

function Cards.wheelmoved(x, y)
    local mx, my = love.mouse.getPosition()
    if mx >= listPanel.x and mx <= listPanel.x + listPanel.w and my >= listPanel.y and my <= listPanel.y + listPanel.h then
        listScroll = listScroll - y * 40
        clampScroll()
    end
end

function Cards.exit()
end

return Cards
