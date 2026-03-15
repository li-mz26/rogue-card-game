local Cards = {}

local UnitCards = require('src.cards.unit_cards')
local CardRenderer = require('src.cards.card_renderer')

local fonts = {}
local backgroundImage = nil
local listPanelBgImage = nil
local detailPanelBgImage = nil
local multiSelectTopImg = nil
local multiSelectOptionImg = nil
local buttonImg = nil
local allCards = {}
local filteredCards = {}

local selectedIndex = 1
local listScroll = 0
local listMaxScroll = 0
local clickAreas = {}

local listPanel = { x = 20, y = 80, w = 0, h = 0 }
local filterBarHeight = 50

local rarityOrder = {
    common = 1,
    uncommon = 2,
    rare = 3,
    legendary = 4,
}

-- Filter state
local filters = {
    rarity = "all",
    dynasty = "all",
    surname = "all",
    origin = "all"
}

-- Available filter options (populated from cards)
local availableDynasties = {}
local availableSurnames = {}
local availableOrigins = {}

-- Filter UI state
local activeDropdown = nil
local dropdownAreas = {}  -- Separate click areas for dropdowns

local function getFont(size)
    if fonts[size] then return fonts[size] end
    local fontPaths = {
        "assets/fonts/feibo.otf",
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

local function drawLayeredCard(card, x, y, w, h, selected, portraitOnly)
    CardRenderer.drawCard(card, x, y, w, h, {
        selected = selected,
        time = love.timer.getTime(),
        portraitOnly = portraitOnly or false
    })
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

local function collectFilterOptions()
    local dynasties = {}
    local surnames = {}
    local origins = {}

    for _, card in ipairs(allCards) do
        local tags = UnitCards.TAGS and UnitCards.TAGS[card.id] or card.tags or {}
        if tags.dynasty and not dynasties[tags.dynasty] then
            dynasties[tags.dynasty] = true
        end
        if tags.surname and not surnames[tags.surname] then
            surnames[tags.surname] = true
        end
        if tags.origin and not origins[tags.origin] then
            origins[tags.origin] = true
        end
    end

    availableDynasties = {}
    for k, _ in pairs(dynasties) do table.insert(availableDynasties, k) end
    table.sort(availableDynasties)

    availableSurnames = {}
    for k, _ in pairs(surnames) do table.insert(availableSurnames, k) end
    table.sort(availableSurnames)

    availableOrigins = {}
    for k, _ in pairs(origins) do table.insert(availableOrigins, k) end
    table.sort(availableOrigins)
end

local function applyFilters()
    filteredCards = {}

    for _, card in ipairs(allCards) do
        -- Rarity filter
        if filters.rarity ~= "all" and card.rarity ~= filters.rarity then
            goto continue
        end

        -- Dynasty, surname, origin filters
        local tags = UnitCards.TAGS and UnitCards.TAGS[card.id] or card.tags or {}

        if filters.dynasty ~= "all" and tags.dynasty ~= filters.dynasty then
            goto continue
        end

        if filters.surname ~= "all" and tags.surname ~= filters.surname then
            goto continue
        end

        if filters.origin ~= "all" and tags.origin ~= filters.origin then
            goto continue
        end

        table.insert(filteredCards, card)

        ::continue::
    end

    if selectedIndex > #filteredCards then
        selectedIndex = math.max(1, #filteredCards)
    end

    listScroll = 0
end

local function clampScroll()
    if listScroll < 0 then listScroll = 0 end
    if listScroll > listMaxScroll then listScroll = listMaxScroll end
end

local function addClickArea(area)
    table.insert(clickAreas, area)
end

-- Dropdown dimensions (stored for later drawing)
local dropdownData = {}

local function drawTopBar(screenWidth)
    love.graphics.setColor(0.92, 0.86, 0.64, 1)
    love.graphics.setFont(getFont(28))
    love.graphics.print("Card Collection", 20, 14)

    local backBtn = { x = screenWidth - 170, y = 14, w = 140, h = 36, type = "back" }
    local mx, my = love.mouse.getPosition()
    local hovered = mx >= backBtn.x and mx <= backBtn.x + backBtn.w and my >= backBtn.y and my <= backBtn.y + backBtn.h

    -- Draw button with image or fallback
    if buttonImg then
        local imgW, imgH = buttonImg:getWidth(), buttonImg:getHeight()
        local scale = math.max(backBtn.w / imgW, backBtn.h / imgH)
        local drawW, drawH = imgW * scale, imgH * scale
        local offsetX, offsetY = (drawW - backBtn.w) / 2, (drawH - backBtn.h) / 2
        love.graphics.setColor(1, 1, 1, hovered and 1 or 0.85)
        love.graphics.draw(buttonImg, backBtn.x - offsetX, backBtn.y - offsetY, 0, scale, scale)
    else
        love.graphics.setColor(hovered and 0.34 or 0.24, hovered and 0.50 or 0.35, hovered and 0.76 or 0.55, 1)
        love.graphics.rectangle("fill", backBtn.x, backBtn.y, backBtn.w, backBtn.h, 8)
        love.graphics.setColor(0.78, 0.86, 1.00, 1)
        love.graphics.rectangle("line", backBtn.x, backBtn.y, backBtn.w, backBtn.h, 8)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(getFont(15))
    local t = "Back To Menu"
    local tw = getFont(15):getWidth(t)
    love.graphics.print(t, backBtn.x + (backBtn.w - tw) / 2, backBtn.y + 9)
    addClickArea(backBtn)
end

local function drawFilterBar(screenWidth)
    local barY = 64
    local barH = filterBarHeight

    local mx, my = love.mouse.getPosition()
    love.graphics.setFont(getFont(13))

    -- Calculate available width (match list panel width)
    local panelW = math.floor(screenWidth * 0.53)
    local startX = 25
    local y = barY + 10
    local dropdownH = 22
    local gap = 30  -- 6 * 1.3 ≈ 8

    -- Calculate dropdown width to fit all filters in panel
    -- 4 dropdowns + 1 reset button, each with label
    local labelW = 38
    local resetW = 45
    local totalLabelsW = labelW * 4 + resetW
    local remainingW = panelW - totalLabelsW - startX - 20
    local dropdownW = math.floor(remainingW / 4)
    dropdownW = math.min(dropdownW, 65)  -- Cap max width

    dropdownData = {}

    local rarityLabels = { all = "全部", common = "普通", uncommon = "稀有", rare = "史诗", legendary = "传说" }

    local x = startX

    -- Helper to draw image as button background
    local function drawImgButton(img, btnX, btnY, btnW, btnH)
        if img then
            local imgW, imgH = img:getWidth(), img:getHeight()
            local scale = math.max(btnW / imgW, btnH / imgH)
            local drawW, drawH = imgW * scale, imgH * scale
            local offsetX, offsetY = (drawW - btnW) / 2, (drawH - btnH) / 2
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, btnX - offsetX, btnY - offsetY, 0, scale, scale)
        end
    end

    -- Helper to draw dropdown button
    local function drawDropdownBtn(label, key, value, displayText)
        -- Draw label (black)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(label, x, y + 3)
        x = x + labelW

        -- Draw dropdown box with image or fallback
        local hovered = mx >= x and mx <= x + dropdownW and my >= y and my <= y + dropdownH
        if multiSelectTopImg then
            drawImgButton(multiSelectTopImg, x, y, dropdownW, dropdownH)
        else
            love.graphics.setColor(hovered and 0.35 or 0.20, hovered and 0.42 or 0.28, hovered and 0.52 or 0.35, 1)
            love.graphics.rectangle("fill", x, y, dropdownW, dropdownH, 3)
        end
        -- Draw text (black)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(displayText, x + 6, y + 3)

        -- Store click area
        addClickArea({ type = "dropdown", key = key, x = x, y = y, w = dropdownW, h = dropdownH })

        -- Store dropdown data for later drawing
        table.insert(dropdownData, {
            key = key,
            x = x,
            y = y,
            w = dropdownW,
            h = dropdownH,
            value = value,
            hovered = hovered
        })

        x = x + dropdownW + gap
    end

    -- Draw all filters
    drawDropdownBtn("品质:", "rarity", filters.rarity, rarityLabels[filters.rarity] or "全部")
    drawDropdownBtn("朝代:", "dynasty", filters.dynasty, filters.dynasty == "all" and "全部" or filters.dynasty)
    drawDropdownBtn("姓氏:", "surname", filters.surname, filters.surname == "all" and "全部" or filters.surname)
    drawDropdownBtn("籍贯:", "origin", filters.origin, filters.origin == "all" and "全部" or filters.origin)

    -- Reset button
    local resetHovered = mx >= x and mx <= x + resetW and my >= y and my <= y + dropdownH
    love.graphics.setColor(resetHovered and 0.55 or 0.35, resetHovered and 0.25 or 0.18, resetHovered and 0.25 or 0.18, 1)
    love.graphics.rectangle("fill", x, y, resetW, dropdownH, 3)
    -- Draw text (black)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("重置", x + 8, y + 3)
    addClickArea({ type = "resetFilters", x = x, y = y, w = resetW, h = dropdownH })

    -- Show filter count on second line (black)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setFont(getFont(11))
    love.graphics.print(string.format("显示: %d/%d", #filteredCards, #allCards), startX, barY + 35)
end

-- Draw dropdown options on top of everything
local function drawDropdownOptions()
    if not activeDropdown then return end

    local mx, my = love.mouse.getPosition()
    love.graphics.setFont(getFont(13))

    local rarityLabels = { all = "全部", common = "普通", uncommon = "稀有", rare = "史诗", legendary = "传说" }

    -- Helper to draw option background image
    local function drawOptionImg(img, optX, optY, optW, optH)
        if img then
            local imgW, imgH = img:getWidth(), img:getHeight()
            local scale = math.max(optW / imgW, optH / imgH)
            local drawW, drawH = imgW * scale, imgH * scale
            local offsetX, offsetY = (drawW - optW) / 2, (drawH - optH) / 2
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, optX - offsetX, optY - offsetY, 0, scale, scale)
        end
    end

    for _, dd in ipairs(dropdownData) do
        if dd.key == activeDropdown then
            local options = {}
            local labels = {}

            if dd.key == "rarity" then
                options = { "all", "common", "uncommon", "rare", "legendary" }
                labels = rarityLabels
            elseif dd.key == "dynasty" then
                options = { "all" }
                for _, d in ipairs(availableDynasties) do table.insert(options, d) end
                labels = setmetatable({}, { __index = function(_, k) return k == "all" and "全部" or k end })
            elseif dd.key == "surname" then
                options = { "all" }
                for _, s in ipairs(availableSurnames) do table.insert(options, s) end
                labels = setmetatable({}, { __index = function(_, k) return k == "all" and "全部" or k end })
            elseif dd.key == "origin" then
                options = { "all" }
                for _, o in ipairs(availableOrigins) do table.insert(options, o) end
                labels = setmetatable({}, { __index = function(_, k) return k == "all" and "全部" or k end })
            end

            for i, opt in ipairs(options) do
                local optY = dd.y + dd.h + (i - 1) * dd.h
                local optHovered = mx >= dd.x and mx <= dd.x + dd.w and my >= optY and my <= optY + dd.h

                -- Draw background with image or fallback
                if multiSelectOptionImg then
                    drawOptionImg(multiSelectOptionImg, dd.x, optY, dd.w, dd.h)
                else
                    love.graphics.setColor(optHovered and 0.32 or 0.18, optHovered and 0.40 or 0.26, optHovered and 0.50 or 0.33, 1)
                    love.graphics.rectangle("fill", dd.x, optY, dd.w, dd.h, 3)
                end

                -- Draw text (black)
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.print(labels[opt] or opt, dd.x + 6, optY + 3)

                -- Add click area
                addClickArea({ type = "dropdownOption", key = dd.key, value = opt, x = dd.x, y = optY, w = dd.w, h = dd.h })
            end
        end
    end
end

local function drawListPanel(screenWidth, screenHeight)
    listPanel.x = 20
    listPanel.y = 80 + filterBarHeight
    listPanel.w = math.floor(screenWidth * 0.53)
    listPanel.h = screenHeight - 120 - filterBarHeight

    -- Draw scrolling background with infinite vertical tiling
    love.graphics.setScissor(listPanel.x, listPanel.y, listPanel.w, listPanel.h)
    if listPanelBgImage then
        local bgH = listPanelBgImage:getHeight()
        local bgW = listPanelBgImage:getWidth()
        local scale = listPanel.w / bgW
        local scaledBgH = bgH * scale

        -- Calculate offset based on scroll (same direction as cards)
        local scrollOffset = listScroll * 0.5  -- Parallax effect
        local offsetY = scrollOffset % scaledBgH

        -- Draw tiled background
        love.graphics.setColor(1, 1, 1, 1)
        local startY = listPanel.y - offsetY
        local y = startY
        while y < listPanel.y + listPanel.h + scaledBgH do
            love.graphics.draw(listPanelBgImage, listPanel.x, y, 0, scale, scale)
            y = y + scaledBgH
        end
    else
        love.graphics.setColor(0.08, 0.11, 0.17, 0.95)
        love.graphics.rectangle("fill", listPanel.x, listPanel.y, listPanel.w, listPanel.h, 10)
    end
    love.graphics.setScissor()

    -- 4 columns layout
    local pad = 10
    local gapX = 10
    local gapY = 10
    local cols = 4
    local cardW = math.floor((listPanel.w - pad * 2 - gapX * (cols - 1)) / cols)
    local cardH = math.floor(cardW * 1.4)

    local contentX = listPanel.x + pad
    local contentY = listPanel.y + pad - listScroll

    local rows = math.ceil(#filteredCards / cols)
    local contentHeight = rows * cardH + math.max(0, rows - 1) * gapY
    listMaxScroll = math.max(0, contentHeight - (listPanel.h - pad * 2))
    clampScroll()

    -- Use stencil/scissor to clip cards within panel (same as listPanel)
    love.graphics.setScissor(listPanel.x, listPanel.y, listPanel.w, listPanel.h)

    for i, card in ipairs(filteredCards) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = contentX + col * (cardW + gapX)
        local y = contentY + row * (cardH + gapY)

        -- Draw card
        drawLayeredCard(card, x, y, cardW, cardH, i == selectedIndex)

        -- Add click area for visible cards only
        if y + cardH >= listPanel.y and y <= listPanel.y + listPanel.h then
            addClickArea({ type = "card", index = i, x = x, y = y, w = cardW, h = cardH })
        end
    end

    love.graphics.setScissor()

    -- Draw scrollbar
    if listMaxScroll > 0 then
        local trackX = listPanel.x + listPanel.w - 12
        local trackY = listPanel.y
        local trackH = listPanel.h
        local thumbH = math.max(42, trackH * ((listPanel.h) / (contentHeight + listPanel.h)))
        local thumbY = trackY + (listScroll / listMaxScroll) * (trackH - thumbH)
        love.graphics.setColor(0.18, 0.25, 0.38, 1)
        love.graphics.rectangle("fill", trackX, trackY, 5, trackH, 3)
        love.graphics.setColor(0.46, 0.64, 0.96, 1)
        love.graphics.rectangle("fill", trackX, thumbY, 5, thumbH, 3)
    end
end

local function drawDetailPanel(screenWidth, screenHeight)
    local x = math.floor(screenWidth * 0.56)
    local y = 80 + filterBarHeight
    local w = math.floor(screenWidth * 0.4)
    local h = screenHeight - 100 - filterBarHeight

    -- Draw background image or fallback
    if detailPanelBgImage then
        local bgW = detailPanelBgImage:getWidth()
        local bgH = detailPanelBgImage:getHeight()
        local scaleX = w / bgW
        local scaleY = h / bgH
        local drawW = bgW * scaleX
        local drawH = bgH * scaleY
        local offsetX = (drawW - w) / 2
        local offsetY = (drawH - h) / 2
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(detailPanelBgImage, x - offsetX, y - offsetY, 0, scaleX, scaleY)
    else
        love.graphics.setColor(0.08, 0.10, 0.15, 0.95)
        love.graphics.rectangle("fill", x, y, w, h, 10)
    end

    local card = filteredCards[selectedIndex]
    if not card then return end

    -- Get card stats
    local stats = UnitCards.getCardStats(card)

    local cardW = math.min(272, w - 26)  -- 340 * 0.8 = 272
    local cardH = math.floor(cardW * 1.42)
    local cardX = x + math.floor((w - cardW) / 2)
    local cardY = y - h * 0.08  -- Move up 8% (15% up then 7% down)
    drawLayeredCard(card, cardX, cardY, cardW, cardH, true, true)  -- portraitOnly = true

    -- Draw stats below portrait (shift right 15% of panel width)
    local statOffsetX = w * 0.15
    local statY = cardY + cardH + 15
    local statLabels = {
        { key = "martial", label = "武力", value = stats.martial },
        { key = "strategy", label = "智谋", value = stats.strategy },
        { key = "command", label = "统率", value = stats.command },
        { key = "defense", label = "防御", value = stats.defense },
        { key = "speed", label = "速度", value = stats.speed },
        { key = "vitality", label = "体力", value = stats.vitality },
    }

    -- Draw stats in two columns (black text)
    love.graphics.setFont(getFont(28))
    local colW = (w - 28) / 2
    local rowH = 36
    for i, stat in ipairs(statLabels) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local statX = x + statOffsetX + col * colW
        local statPosY = statY + row * rowH

        -- Label (black)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(stat.label .. ":", statX, statPosY)

        -- Value (black)
        love.graphics.setColor(0, 0, 0, 1)
        local valueStr = tostring(stat.value)
        love.graphics.print(valueStr, statX + 85, statPosY)
    end

    -- Description (black)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setFont(getFont(26))
    local desc = card.description or "No description"
    local textY = statY + rowH * 3 + 15
    love.graphics.printf(desc, x + statOffsetX, textY, w - 28 - statOffsetX, "left")

    -- Show tags info (black)
    local tags = UnitCards.TAGS and UnitCards.TAGS[card.id] or card.tags or {}
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setFont(getFont(24))
    local tagY = textY + 50
    if tags.dynasty then
        love.graphics.print("朝代: " .. tags.dynasty, x + statOffsetX, tagY)
        tagY = tagY + 30
    end
    if tags.surname then
        love.graphics.print("姓氏: " .. tags.surname, x + statOffsetX, tagY)
        tagY = tagY + 30
    end
    if tags.origin then
        love.graphics.print("籍贯: " .. tags.origin, x + statOffsetX, tagY)
    end
end

function Cards.init()
    allCards = {}
    for _, card in ipairs(UnitCards.getAll()) do
        table.insert(allCards, card)
    end
    sortCards()

    collectFilterOptions()
    applyFilters()

    selectedIndex = 1
    listScroll = 0
    listMaxScroll = 0
    clickAreas = {}
    activeDropdown = nil
    dropdownData = {}

    local ok, img = pcall(love.graphics.newImage, "assets/images/backgrounds/bg_cards.png")
    if ok and img then
        backgroundImage = img
        backgroundImage:setFilter("linear", "linear")
    end

    local ok2, img2 = pcall(love.graphics.newImage, "assets/images/backgrounds/card_scroll.png")
    if ok2 and img2 then
        listPanelBgImage = img2
        listPanelBgImage:setFilter("linear", "linear")
    end

    local ok3, img3 = pcall(love.graphics.newImage, "assets/images/backgrounds/card_detail.png")
    if ok3 and img3 then
        detailPanelBgImage = img3
        detailPanelBgImage:setFilter("linear", "linear")
    end

    local ok4, img4 = pcall(love.graphics.newImage, "assets/images/backgrounds/multi_select_top.png")
    if ok4 and img4 then
        multiSelectTopImg = img4
        multiSelectTopImg:setFilter("linear", "linear")
    end

    local ok5, img5 = pcall(love.graphics.newImage, "assets/images/backgrounds/multi_select_option.png")
    if ok5 and img5 then
        multiSelectOptionImg = img5
        multiSelectOptionImg:setFilter("linear", "linear")
    end

    local ok6, img6 = pcall(love.graphics.newImage, "assets/images/backgrounds/button1.png")
    if ok6 and img6 then
        buttonImg = img6
        buttonImg:setFilter("linear", "linear")
    end

    CardRenderer.init()
end

function Cards.update(dt)
end

function Cards.draw()
    clickAreas = {}
    dropdownData = {}

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    -- Draw background
    if backgroundImage then
        love.graphics.setColor(1, 1, 1, 1)
        local scale = math.max(sw / backgroundImage:getWidth(), sh / backgroundImage:getHeight())
        local drawW = backgroundImage:getWidth() * scale
        local drawH = backgroundImage:getHeight() * scale
        local offsetX = (drawW - sw) / 2
        local offsetY = (drawH - sh) / 2
        love.graphics.draw(backgroundImage, -offsetX, -offsetY, 0, scale, scale)
    else
        love.graphics.setColor(0.04, 0.06, 0.10, 1)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
    end

    -- Draw UI layers (bottom to top)
    drawTopBar(sw)
    drawFilterBar(sw)
    drawListPanel(sw, sh)
    drawDetailPanel(sw, sh)

    -- Draw dropdown options on top of everything
    drawDropdownOptions()
end

function Cards.mousepressed(x, y, button)
    if button ~= 1 then return end

    -- Check click areas in reverse order (top to bottom)
    for i = #clickAreas, 1, -1 do
        local a = clickAreas[i]
        if x >= a.x and x <= a.x + a.w and y >= a.y and y <= a.y + a.h then
            if a.type == "card" then
                selectedIndex = a.index
                activeDropdown = nil
                return
            elseif a.type == "back" then
                local GameState = require('src.game.gamestate')
                GameState.switch("menu")
                return
            elseif a.type == "dropdown" then
                if activeDropdown == a.key then
                    activeDropdown = nil
                else
                    activeDropdown = a.key
                end
                return
            elseif a.type == "dropdownOption" then
                filters[a.key] = a.value
                activeDropdown = nil
                applyFilters()
                return
            elseif a.type == "resetFilters" then
                filters.rarity = "all"
                filters.dynasty = "all"
                filters.surname = "all"
                filters.origin = "all"
                activeDropdown = nil
                applyFilters()
                return
            end
        end
    end

    -- Click outside closes dropdown
    activeDropdown = nil
end

function Cards.wheelmoved(x, y)
    -- Don't scroll if dropdown is open
    if activeDropdown then return end

    local mx, my = love.mouse.getPosition()
    if mx >= listPanel.x and mx <= listPanel.x + listPanel.w and my >= listPanel.y and my <= listPanel.y + listPanel.h then
        listScroll = listScroll - y * 40
        clampScroll()
    end
end

function Cards.exit()
end

return Cards