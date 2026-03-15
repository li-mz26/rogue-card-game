--[[
    Card Renderer - FIFA/NBA2K Style
    Layered card rendering with:
    0. Background (stylized, abstract elements)
    1. Overall Rating (top-left, artistic font)
    2. Six-dimensional stats (bottom half, radar chart)
    3. Character Portrait
--]]

local CardRenderer = {}
local UnitCards = require('src.cards.unit_cards')

local fonts = {}
local images = {}

-- Background mapping: rarity -> background image name
local rarityBackgroundMap = {
    common = "bg_white",
    uncommon = "bg_green",
    rare = "bg_blue",
    legendary = "bg_gold"
}

-- Rating badge mapping: rarity -> badge frame image name
local rarityBadgeMap = {
    common = "rates_white",
    uncommon = "rates_green",
    rare = "rates_blue",
    legendary = "rates_gold"
}

-- Stats panel background mapping: rarity -> score panel image name
local rarityScoreMap = {
    common = "score_white",
    uncommon = "score_green",
    rare = "score_blue",
    legendary = "score_gold"
}

-- Color schemes by rarity (updated to match new backgrounds)
local rarityColors = {
    common = {
        primary = {0.70, 0.72, 0.78},
        secondary = {0.50, 0.52, 0.58},
        accent = {0.85, 0.87, 0.92},
        glow = {0.75, 0.78, 0.82}
    },
    uncommon = {
        primary = {0.20, 0.75, 0.40},
        secondary = {0.12, 0.52, 0.28},
        accent = {0.40, 0.88, 0.55},
        glow = {0.28, 0.82, 0.48}
    },
    rare = {
        primary = {0.25, 0.48, 0.92},
        secondary = {0.15, 0.32, 0.72},
        accent = {0.45, 0.65, 0.98},
        glow = {0.32, 0.52, 0.95}
    },
    legendary = {
        primary = {0.96, 0.70, 0.18},
        secondary = {0.82, 0.52, 0.08},
        accent = {0.98, 0.85, 0.40},
        glow = {0.98, 0.75, 0.28}
    }
}

local function getFont(size)
    if fonts[size] then return fonts[size] end
    local fontPaths = {
        "assets/fonts/feibo.otf",
        "assets/fonts/simhei.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/msyh.ttc",
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
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(img, x, y, 0, w / img:getWidth(), h / img:getHeight())
end

-- Draw a number using image sprites, returns total width drawn
local function drawNumberImage(num, x, y, digitHeight)
    if not images.numbers or not images.numbers[0] then return 0 end

    local numStr = tostring(num)
    local overlap = 0.10  -- 10% overlap on each side
    local totalW = 0
    local digitW = 0

    -- First pass: calculate total width with overlap
    for i = 1, #numStr do
        local digit = tonumber(string.sub(numStr, i, i))
        if digit and images.numbers[digit] then
            local img = images.numbers[digit]
            local scale = digitHeight / img:getHeight()
            digitW = img:getWidth() * scale
            totalW = totalW + digitW
        end
    end
    -- Subtract overlap (n-1 overlaps, each is 2*overlap*digitW, but we approximate with average digitW)
    if #numStr > 1 then
        totalW = totalW - digitW * overlap * 2 * (#numStr - 1)
    end

    -- Second pass: draw digits with overlap
    local curX = x
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1, #numStr do
        local digit = tonumber(string.sub(numStr, i, i))
        if digit and images.numbers[digit] then
            local img = images.numbers[digit]
            local scale = digitHeight / img:getHeight()
            love.graphics.draw(img, curX, y, 0, scale, scale)
            curX = curX + img:getWidth() * scale * (1 - overlap * 2)
        end
    end

    return totalW
end

-- Draw stylized background with abstract elements
local function drawStylizedBackground(x, y, w, h, rarity, time)
    local colors = rarityColors[rarity] or rarityColors.common

    -- Get background image based on rarity mapping
    local bgName = rarityBackgroundMap[rarity] or "bg_white"
    local bgImg = images[bgName]
    if bgImg then
        love.graphics.setColor(1, 1, 1, 1)
        -- Scale to fit card while maintaining aspect ratio
        local scale = math.max(w / bgImg:getWidth(), h / bgImg:getHeight())
        local drawW = bgImg:getWidth() * scale
        local drawH = bgImg:getHeight() * scale
        local offsetX = (drawW - w) / 2
        local offsetY = (drawH - h) / 2
        love.graphics.draw(bgImg, x - offsetX, y - offsetY, 0, scale, scale)
    else
        -- Fallback: Base dark gradient
        for i = 0, math.floor(h) do
            local t = i / h
            local r = 0.06 + t * 0.04
            local g = 0.08 + t * 0.03
            local b = 0.12 + t * 0.05
            love.graphics.setColor(r, g, b, 1)
            love.graphics.line(x, y + i, x + w, y + i)
        end
    end

    -- Abstract geometric patterns overlay
    -- Dynamic lines
    local lineCount = rarity == "legendary" and 18 or (rarity == "rare" and 14 or 10)
    for i = 1, lineCount do
        local angle = (i / lineCount) * math.pi * 2 + time * 0.3
        local cx = x + w * 0.7
        local cy = y + h * 0.35
        local len = w * 0.6
        love.graphics.setColor(colors.primary[1], colors.primary[2], colors.primary[3], 0.08 + 0.04 * math.sin(time * 2 + i))
        love.graphics.setLineWidth(1)
        love.graphics.line(
            cx + math.cos(angle) * len * 0.2,
            cy + math.sin(angle) * len * 0.2,
            cx + math.cos(angle) * len,
            cy + math.sin(angle) * len
        )
    end

    -- Glow spots
    local spotCount = rarity == "legendary" and 5 or 3
    for i = 1, spotCount do
        local spotX = x + w * (0.3 + 0.5 * math.sin(time * 0.5 + i * 2))
        local spotY = y + h * (0.2 + 0.3 * math.cos(time * 0.4 + i * 1.5))
        local spotR = w * (0.15 + 0.1 * math.sin(time + i))
        love.graphics.setColor(colors.glow[1], colors.glow[2], colors.glow[3], 0.06)
        love.graphics.circle("fill", spotX, spotY, spotR)
    end
end

-- Draw overall rating badge (top-left)
local function drawOverallRating(x, y, w, h, rating, rarity, time)
    local colors = rarityColors[rarity] or rarityColors.common

    -- Badge dimensions
    local badgeW = w * 0.28
    local badgeH = h * 0.22
    local badgeX = x + w * 0.04
    local badgeY = y + h * 0.04

    -- Get badge frame image
    local badgeName = rarityBadgeMap[rarity] or "rates_white"
    local badgeImg = images[badgeName]

    if badgeImg then
        -- Draw badge frame image
        love.graphics.setColor(1, 1, 1, 1)
        local scale = math.min(badgeW / badgeImg:getWidth(), badgeH / badgeImg:getHeight())
        local drawW = badgeImg:getWidth() * scale
        local drawH = badgeImg:getHeight() * scale
        local drawX = badgeX + (badgeW - drawW) / 2
        local drawY = badgeY + (badgeH - drawH) / 2
        love.graphics.draw(badgeImg, drawX, drawY, 0, scale, scale)

        -- Rating number (centered in badge) using number images
        local digitH = badgeH * 0.45
        local numW = drawNumberImage(rating, 0, 0, digitH)  -- measure width
        drawNumberImage(rating, badgeX + badgeW * 0.5 - numW * 0.5, badgeY + badgeH * 0.35, digitH)
    else
        -- Fallback: drawn badge
        local pulse = 0.85 + 0.15 * math.sin(time * 3)
        love.graphics.setColor(colors.glow[1], colors.glow[2], colors.glow[3], 0.3 * pulse)
        love.graphics.circle("fill", badgeX + badgeW * 0.5, badgeY + badgeH * 0.55, badgeW * 0.65)

        love.graphics.setColor(0.08, 0.10, 0.14, 1)
        love.graphics.circle("fill", badgeX + badgeW * 0.5, badgeY + badgeH * 0.55, badgeW * 0.52)

        love.graphics.setColor(colors.primary[1], colors.primary[2], colors.primary[3], 1)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", badgeX + badgeW * 0.5, badgeY + badgeH * 0.55, badgeW * 0.52)
        love.graphics.setLineWidth(1)

        -- Rating number using number images
        local digitH = badgeH * 0.5
        local numW = drawNumberImage(rating, 0, 0, digitH)
        drawNumberImage(rating, badgeX + badgeW * 0.5 - numW * 0.5, badgeY + badgeH * 0.25, digitH)
    end
end

-- Draw six-dimensional stats panel (two columns, three rows each)
local function drawStatsPanel(x, y, w, h, stats, rarity, time)
    local colors = rarityColors[rarity] or rarityColors.common

    -- Stats panel background with gradient and border
    local panelX = x + w * 0.04
    -- Original bottom gap was h * 0.05 (5%), now 1/3 of that = h * 0.0167 (1.67%)
    -- panelY + panelH should end at y + h * 0.9833
    local panelH = h * 0.40
    local panelY = y + h * 0.9833 - panelH  -- Position so bottom gap is 1/3 of original
    local panelW = w * 0.92

    -- Get score panel image based on rarity
    local scoreName = rarityScoreMap[rarity] or "score_white"
    local scoreImg = images[scoreName]

    if scoreImg then
        -- Draw score panel background image (keep aspect ratio, don't stretch height)
        love.graphics.setColor(1, 1, 1, 1)
        local imgW = scoreImg:getWidth()
        local imgH = scoreImg:getHeight()
        -- Scale by width only, let height be natural
        local scale = panelW / imgW
        local drawH = imgH * scale
        -- Draw from bottom of panel area
        local drawY = panelY + panelH - drawH
        love.graphics.draw(scoreImg, panelX, drawY, 0, scale, scale)
    else
        -- Fallback: dark semi-transparent background
        love.graphics.setColor(0.04, 0.06, 0.10, 0.92)
        love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8)
    end

    -- Stats data: left column (武力, 智谋, 统率) right column (防御, 速度, 体力)
    local statData = {
        { key = "martial", label = "武力", value = stats.martial },
        { key = "strategy", label = "智谋", value = stats.strategy },
        { key = "command", label = "统率", value = stats.command },
        { key = "defense", label = "防御", value = stats.defense },
        { key = "speed", label = "速度", value = stats.speed },
        { key = "vitality", label = "体力", value = stats.vitality },
    }

    -- Calculate actual content area based on background image
    local contentH = panelH
    if scoreImg then
        local imgW = scoreImg:getWidth()
        local imgH = scoreImg:getHeight()
        local scale = panelW / imgW
        contentH = imgH * scale
    end

    local padding = panelW * 0.05
    local colW = (panelW - padding * 3) / 2
    local rowH = (contentH - padding * 2) / 3
    local rowGap = rowH * 0.1

    for i, stat in ipairs(statData) do
        local col = i <= 3 and 0 or 1
        local row = (i - 1) % 3
        local statX = panelX + padding + col * (colW + padding)
        local statY = panelY + panelH - contentH + padding + row * (rowH + rowGap)

        -- Stat label (Chinese)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(getFont(math.floor(rowH * 0.45)))
        love.graphics.print(stat.label, statX, statY)

        -- Stat value (number) using number images
        local digitH = rowH * 0.5
        local numW = drawNumberImage(stat.value, 0, 0, digitH)  -- measure width
        drawNumberImage(stat.value, statX + colW - numW, statY, digitH)
    end
end

-- Draw character name
local function drawCardInfo(x, y, w, h, card, rarity)
    -- Name (1.5x larger than before)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setFont(getFont(math.floor(w * 0.15)))
    love.graphics.print(card.name or "Unknown", x + w * 0.32, y + h * 0.06)

    -- Rarity badge
    local rarityLabels = { common = "C", uncommon = "U", rare = "R", legendary = "L" }
    local rarityLabel = rarityLabels[rarity] or "C"
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setFont(getFont(math.floor(w * 0.07)))
    love.graphics.print(rarityLabel, x + w * 0.88, y + h * 0.06)
end

-- Draw portrait placeholder
local function drawPortrait(x, y, w, h, portrait, rarity, time)
    if not portrait then return end

    -- Scale to 90% of card width, maintain aspect ratio, centered
    local scale = w * 0.90 / portrait:getWidth()
    local drawW = portrait:getWidth() * scale
    local drawH = portrait:getHeight() * scale
    local drawX = x + (w - drawW) / 2  -- Centered horizontally
    local drawY = y + h * 0.18

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(portrait, drawX, drawY, 0, scale, scale)
end

-- Main render function
function CardRenderer.drawCard(card, x, y, w, h, options)
    options = options or {}
    local selected = options.selected or false
    local time = options.time or love.timer.getTime()
    local rarity = card.rarity or "common"
    local portraitOnly = options.portraitOnly or false

    -- Get six-dimensional stats
    local stats = UnitCards.getCardStats(card)
    local overall = UnitCards.calcOverallRating(stats)

    -- Load images if available
    local portrait = images["portrait_" .. card.id] or images.portrait_default

    if portraitOnly then
        -- Only draw character portrait
        drawPortrait(x, y, w, h, portrait, rarity, time)
    else
        -- Layer 0: Stylized background
        drawStylizedBackground(x, y, w, h, rarity, time)

        -- Layer 3: Character portrait
        drawPortrait(x, y, w, h, portrait, rarity, time)

        -- Layer 1: Overall rating badge
        drawOverallRating(x, y, w, h, overall, rarity, time)

        -- Card info (name, title)
        drawCardInfo(x, y, w, h, card, rarity)

        -- Layer 2: Six-dimensional stats panel
        drawStatsPanel(x, y, w, h, stats, rarity, time)
    end
end

-- Initialize images
function CardRenderer.init()
    -- Load new background images
    images.bg_white = safeLoadImage("assets/cards/backgrounds/bg_white.png")
    images.bg_green = safeLoadImage("assets/cards/backgrounds/bg_green.png")
    images.bg_blue = safeLoadImage("assets/cards/backgrounds/bg_blue.png")
    images.bg_purple = safeLoadImage("assets/cards/backgrounds/bg_purple.png")
    images.bg_gold = safeLoadImage("assets/cards/backgrounds/bg_gold.png")

    -- Load rating badge frames
    images.rates_white = safeLoadImage("assets/cards/blocks/rates_white.png")
    images.rates_green = safeLoadImage("assets/cards/blocks/rates_green.png")
    images.rates_blue = safeLoadImage("assets/cards/blocks/rates_blue.png")
    images.rates_purple = safeLoadImage("assets/cards/blocks/rates_purple.png")
    images.rates_gold = safeLoadImage("assets/cards/blocks/rates_gold.png")

    -- Load stats panel backgrounds (score panels)
    images.score_white = safeLoadImage("assets/cards/blocks/score_white.png")
    images.score_green = safeLoadImage("assets/cards/blocks/score_green.png")
    images.score_blue = safeLoadImage("assets/cards/blocks/score_blue.png")
    images.score_purple = safeLoadImage("assets/cards/blocks/score_purple.png")
    images.score_gold = safeLoadImage("assets/cards/blocks/score_gold.png")

    -- Load number images (0-9)
    images.numbers = {}
    for i = 0, 9 do
        images.numbers[i] = safeLoadImage("assets/cards/numbers/" .. i .. ".png")
    end

    -- Load default portrait
    images.portrait_default = safeLoadImage("assets/cards/placeholders/portrait_warrior.png")

    -- Load all character portraits
    for _, card in ipairs(UnitCards.getAll()) do
        local path = "assets/cards/portraits/" .. card.id .. ".png"
        local img = safeLoadImage(path)
        if img then
            images["portrait_" .. card.id] = img
        end
    end
end

-- Get background image by rarity
function CardRenderer.getBackground(rarity)
    local bgName = rarityBackgroundMap[rarity] or "bg_white"
    return images[bgName]
end

-- Get rarity colors for external use
function CardRenderer.getRarityColors(rarity)
    return rarityColors[rarity] or rarityColors.common
end

return CardRenderer