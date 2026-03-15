local Battle = {}

local GameState = nil
local Deployment = nil
local backgroundImage = nil
local buttonImgs = {}
local CardRenderer = nil  -- Lazy loaded

Battle.ROW = {
    COMMAND = 1,
    VANGUARD = 2,
    CENTER = 3,
    REAR = 4,
}

Battle.ROW_NAME = {
    [Battle.ROW.COMMAND] = "大营",
    [Battle.ROW.VANGUARD] = "前锋",
    [Battle.ROW.CENTER] = "中军",
    [Battle.ROW.REAR] = "后卫",
}

-- Horizontal layout: 8 columns alternating between players
-- Order from left to right: P1 Command, P2 Vanguard, P1 Rear, P2 Center, P1 Center, P2 Rear, P1 Vanguard, P2 Command
Battle.COLUMN_LAYOUT = {
    { player = 1, rowType = Battle.ROW.COMMAND, label = "我方大营" },
    { player = 2, rowType = Battle.ROW.VANGUARD, label = "敌方前锋" },
    { player = 1, rowType = Battle.ROW.REAR, label = "我方后卫" },
    { player = 2, rowType = Battle.ROW.CENTER, label = "敌方中军" },
    { player = 1, rowType = Battle.ROW.CENTER, label = "我方中军" },
    { player = 2, rowType = Battle.ROW.REAR, label = "敌方后卫" },
    { player = 1, rowType = Battle.ROW.VANGUARD, label = "我方前锋" },
    { player = 2, rowType = Battle.ROW.COMMAND, label = "敌方大营" },
}

local chineseFont = {}
local deploymentData = {}

local players = {}
local currentTurn = 1
local currentPhase = "idle"
local activePlayer = 1

local battleLog = {}
local powerBalls = {}
local pendingTurnDelay = nil

local BALL_SPEED = 220
local BALL_RADIUS = 6

local rarityLabel = {
    common = "C",
    uncommon = "U",
    rare = "R",
    legendary = "L",
}

local phaseText = {
    idle = "待机",
    ready = "准备",
    transfer = "传递",
    waiting = "回合切换",
    victory = "胜利",
}

local function isTestMode()
    return rawget(_G, "TEST_MODE") == true
end

local function clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function safeTags(tags)
    if type(tags) == "table" then return tags end
    return {}
end

-- UTF-8 safe string truncation
local function utf8Truncate(str, maxChars)
    if not str then return "" end
    local charCount = 0
    local bytePos = 1
    while bytePos <= #str and charCount < maxChars do
        local b = string.byte(str, bytePos)
        if b < 128 then
            bytePos = bytePos + 1
        elseif b < 224 then
            bytePos = bytePos + 2
        elseif b < 240 then
            bytePos = bytePos + 3
        else
            bytePos = bytePos + 4
        end
        charCount = charCount + 1
    end
    if bytePos <= #str then
        return string.sub(str, 1, bytePos - 1) .. "…"
    end
    return str
end

local function log(message)
    local text = tostring(message or "")
    table.insert(battleLog, text)
    if #battleLog > 50 then
        table.remove(battleLog, 1)
    end
    print(text)
end

local function loadChineseFonts()
    if chineseFont[16] then return true end

    local fontPaths = {
        "assets/fonts/simhei.ttf",
        "assets/fonts/simkai.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/simkai.ttf",
        "C:/Windows/Fonts/msyh.ttc",
        "C:/Windows/Fonts/msyhbd.ttc",
        "C:/Windows/Fonts/simsun.ttc",
    }

    for _, path in ipairs(fontPaths) do
        local ok = pcall(function()
            chineseFont[9] = love.graphics.newFont(path, 9)
            chineseFont[10] = love.graphics.newFont(path, 10)
            chineseFont[12] = love.graphics.newFont(path, 12)
            chineseFont[14] = love.graphics.newFont(path, 14)
            chineseFont[16] = love.graphics.newFont(path, 16)
            chineseFont[18] = love.graphics.newFont(path, 18)
            chineseFont[20] = love.graphics.newFont(path, 20)
            chineseFont[24] = love.graphics.newFont(path, 24)
        end)
        if ok then
            return true
        end
    end

    chineseFont[9] = love.graphics.newFont(9)
    chineseFont[10] = love.graphics.newFont(10)
    chineseFont[12] = love.graphics.newFont(12)
    chineseFont[14] = love.graphics.newFont(14)
    chineseFont[16] = love.graphics.newFont(16)
    chineseFont[18] = love.graphics.newFont(18)
    chineseFont[20] = love.graphics.newFont(20)
    chineseFont[24] = love.graphics.newFont(24)
    print("Warning: could not load Chinese font, fallback to default")
    return false
end

local function getFont(size)
    if not chineseFont[size] then
        local ok, f = pcall(love.graphics.newFont, size)
        if ok and f then
            chineseFont[size] = f
        end
    end
    return chineseFont[size] or love.graphics.getFont()
end

local function getRarityColor(rarity)
    local colors = {
        common = {0.7, 0.7, 0.7},
        uncommon = {0.2, 0.8, 0.2},
        rare = {0.2, 0.5, 1},
        legendary = {1, 0.8, 0.2},
    }
    return colors[rarity] or colors.common
end

local function calcTagSynergy(tagsA, tagsB)
    local a = safeTags(tagsA)
    local b = safeTags(tagsB)
    local score = 0
    if a.dynasty and b.dynasty and a.dynasty == b.dynasty then score = score + 0.04 end
    if a.surname and b.surname and a.surname == b.surname then score = score + 0.03 end
    if a.origin and b.origin and a.origin == b.origin then score = score + 0.03 end
    return score
end

local function normalizeUnitTransferStats(unit, rowType)
    unit.sendPower = unit.sendPower or unit.send or 0.55
    unit.recvPower = unit.recvPower or unit.recv or 0.55
    unit.interceptPower = unit.interceptPower or unit.intercept or 0.12
    unit.powerMod = unit.powerMod or unit.transferMod or 0
    unit.tags = safeTags(unit.tags)

    if rowType == Battle.ROW.VANGUARD then
        unit.sendPower = unit.sendPower + 0.06
    elseif rowType == Battle.ROW.REAR then
        unit.recvPower = unit.recvPower + 0.06
    end

    for _, ability in ipairs(unit.abilities or {}) do
        if ability.type == "bonus_transfer" then
            unit.powerMod = unit.powerMod + (ability.value or 0)
        elseif ability.type == "defend" then
            unit.interceptPower = unit.interceptPower + (ability.value or 0) * 0.6
        elseif ability.type == "ambush" then
            unit.interceptPower = unit.interceptPower + (ability.value or 0) * 0.08
        elseif ability.type == "charge" then
            unit.sendPower = unit.sendPower + (ability.value or 0) * 0.06
        end
    end

    unit.sendPower = clamp(unit.sendPower, 0.1, 1.2)
    unit.recvPower = clamp(unit.recvPower, 0.1, 1.2)
    unit.interceptPower = clamp(unit.interceptPower, 0, 0.9)
    unit.powerMod = clamp(unit.powerMod, -0.4, 1.2)
end

local function calcTransferSuccessRate(sender, receiver, interceptor)
    local send = sender.sendPower or 0.5
    local recv = receiver.recvPower or 0.5
    local intercept = interceptor and (interceptor.interceptPower or 0) or 0
    local synergy = calcTagSynergy(sender.tags, receiver.tags)
    local p = 0.35 + 0.35 * send + 0.25 * recv + synergy - 0.45 * intercept
    return clamp(p, 0.05, 0.98)
end

local function applyPowerModifier(power, sender, receiver)
    local senderMod = sender.powerMod or 0
    local receiverMod = receiver.powerMod or 0
    local factor = 1 + senderMod + receiverMod * 0.5
    factor = clamp(factor, 0.5, 2.2)
    return power * factor
end

local function createUnit(row, index, card)
    if card then
        local unit = {
            row = row,
            index = index,
            card = card,
            name = card.name or (Battle.ROW_NAME[row] .. index),
            attack = card.attack or ((row == Battle.ROW.VANGUARD) and 1 or 0),
            defense = card.defense or 0,
            currentPower = 0,
            maxPower = 10,
            abilities = card.abilities or {},
            sendPower = card.sendPower,
            recvPower = card.recvPower,
            interceptPower = card.interceptPower,
            powerMod = card.powerMod,
            rarity = card.rarity,
            tags = safeTags(card.tags),
        }
        normalizeUnitTransferStats(unit, row)
        return unit
    end

    local unit = {
        row = row,
        index = index,
        card = nil,
        name = Battle.ROW_NAME[row] .. index,
        attack = (row == Battle.ROW.VANGUARD) and 1 or 0,
        defense = 0,
        currentPower = 0,
        maxPower = 10,
        abilities = {},
        rarity = "common",
        tags = {},
    }
    normalizeUnitTransferStats(unit, row)
    return unit
end

local function processRowUnits(units, rowType)
    local result = {}
    for i, unit in ipairs(units or {}) do
        result[i] = createUnit(rowType, i, unit)
    end
    return result
end

local function createPlayerFromDeployment(id, name, data)
    local player = {
        id = id,
        name = name,
        command = nil,
        commandHp = 30,
        maxCommandHp = 30,
        units = {
            [Battle.ROW.COMMAND] = {},
            [Battle.ROW.VANGUARD] = {},
            [Battle.ROW.CENTER] = {},
            [Battle.ROW.REAR] = {},
        },
        basePowerGeneration = 5,
        rowCounts = {
            [Battle.ROW.VANGUARD] = 3,
            [Battle.ROW.CENTER] = 3,
            [Battle.ROW.REAR] = 3,
        },
    }

    if not data then
        return player
    end

    if data.command then
        player.command = createUnit(Battle.ROW.COMMAND, 1, data.command)
        player.commandHp = data.command.hp or 30
        player.maxCommandHp = data.command.hp or 30

        for _, ability in ipairs(data.command.abilities or {}) do
            if ability.type == "bonus_generate" then
                player.basePowerGeneration = player.basePowerGeneration + (ability.value or 0)
            elseif ability.type == "bonus_transfer" then
                player.command.powerMod = (player.command.powerMod or 0) + (ability.value or 0)
            end
        end
        normalizeUnitTransferStats(player.command, Battle.ROW.COMMAND)
    end

    player.units[Battle.ROW.VANGUARD] = processRowUnits(data.vanguard, Battle.ROW.VANGUARD)
    player.units[Battle.ROW.CENTER] = processRowUnits(data.center, Battle.ROW.CENTER)
    player.units[Battle.ROW.REAR] = processRowUnits(data.rear, Battle.ROW.REAR)

    if data.rowCounts then
        player.rowCounts[Battle.ROW.VANGUARD] = data.rowCounts.vanguard or player.rowCounts[Battle.ROW.VANGUARD]
        player.rowCounts[Battle.ROW.CENTER] = data.rowCounts.center or player.rowCounts[Battle.ROW.CENTER]
        player.rowCounts[Battle.ROW.REAR] = data.rowCounts.rear or player.rowCounts[Battle.ROW.REAR]
    end

    return player
end

local function createDefaultPlayer(id, name)
    local player = {
        id = id,
        name = name,
        command = createUnit(Battle.ROW.COMMAND, 1, {
            name = "主将",
            hp = 30,
            sendPower = 0.72,
            recvPower = 0.78,
            interceptPower = 0.16,
            rarity = "rare",
            abilities = {},
            tags = {},
        }),
        commandHp = 30,
        maxCommandHp = 30,
        units = {
            [Battle.ROW.COMMAND] = {},
            [Battle.ROW.VANGUARD] = {
                createUnit(Battle.ROW.VANGUARD, 1),
                createUnit(Battle.ROW.VANGUARD, 2),
                createUnit(Battle.ROW.VANGUARD, 3),
            },
            [Battle.ROW.CENTER] = {
                createUnit(Battle.ROW.CENTER, 1),
                createUnit(Battle.ROW.CENTER, 2),
                createUnit(Battle.ROW.CENTER, 3),
            },
            [Battle.ROW.REAR] = {
                createUnit(Battle.ROW.REAR, 1),
                createUnit(Battle.ROW.REAR, 2),
                createUnit(Battle.ROW.REAR, 3),
            },
        },
        basePowerGeneration = 5,
        rowCounts = {
            [Battle.ROW.VANGUARD] = 3,
            [Battle.ROW.CENTER] = 3,
            [Battle.ROW.REAR] = 3,
        },
    }
    return player
end

local function ensureOpponentData()
    if deploymentData and deploymentData.player2 then
        return deploymentData.player2
    end

    if not Deployment then
        Deployment = require('src.game.deployment')
    end
    Deployment.init(2)
    Deployment.autoDeploy()
    return Deployment.getDeploymentResult()
end

local function getRowSlots(player, rowType)
    local result = {}
    local maxCount = (player.rowCounts and player.rowCounts[rowType]) or 3
    local rowUnits = player.units[rowType] or {}
    for i = 1, maxCount do
        local unit = rowUnits[i]
        if unit then
            table.insert(result, { unit = unit, index = i })
        end
    end
    return result
end

local function chooseTargetByDistribution(sender, slots)
    if #slots == 0 then return nil end
    local total = 0
    local weights = {}
    for i, slot in ipairs(slots) do
        local unit = slot.unit
        local synergy = calcTagSynergy(sender.tags, unit.tags)
        local w = 1 + (unit.recvPower or 0.5) * 1.2 + synergy * 5 + (unit.powerMod or 0) * 0.6
        w = math.max(0.05, w)
        weights[i] = w
        total = total + w
    end
    local roll = math.random() * total
    local acc = 0
    for i, w in ipairs(weights) do
        acc = acc + w
        if roll <= acc then return slots[i] end
    end
    return slots[#slots]
end

local function findNearestEnemyInterceptor(defender, rowType, laneIndex)
    local slots = getRowSlots(defender, rowType)
    if #slots == 0 then return nil end
    local best = slots[1]
    local bestDist = math.abs((best.index or 1) - (laneIndex or 1))
    for i = 2, #slots do
        local dist = math.abs((slots[i].index or 1) - (laneIndex or 1))
        if dist < bestDist then
            best = slots[i]
            bestDist = dist
        end
    end
    return best.unit
end

local function getUnitPosition(playerId, rowType, unitIndex, screenWidth, screenHeight)
    -- Find which column this unit belongs to
    local colIndex = nil
    for i, col in ipairs(Battle.COLUMN_LAYOUT) do
        if col.player == playerId and col.rowType == rowType then
            colIndex = i
            break
        end
    end
    if not colIndex then return nil end

    -- Calculate column position
    local numCols = #Battle.COLUMN_LAYOUT
    local colWidth = screenWidth / numCols
    local colCenterX = colWidth * (colIndex - 0.5)

    -- Calculate card dimensions
    local cardW = colWidth * 0.7
    local cardH = cardW * 1.4
    local cardGap = 5

    -- Get the player and count units in this row
    local player = players[playerId]
    if not player then return nil end

    local units = player.units[rowType] or {}
    local numUnits = 0
    for _ in ipairs(units) do
        numUnits = numUnits + 1
    end

    if numUnits == 0 then return nil end

    -- Calculate total height and center the stack around center axis
    local centerY = screenHeight / 2
    local totalHeight = numUnits * cardH + math.max(0, numUnits - 1) * cardGap
    local startY = centerY - totalHeight / 2

    -- Calculate Y position for this unit (1-indexed)
    local cardY = startY + (unitIndex - 1) * (cardH + cardGap)

    return { x = colCenterX, y = cardY + cardH / 2 }
end

local function getCommandPosition(playerId, screenWidth, screenHeight)
    -- Find command column for this player
    local colIndex = nil
    for i, col in ipairs(Battle.COLUMN_LAYOUT) do
        if col.player == playerId and col.rowType == Battle.ROW.COMMAND then
            colIndex = i
            break
        end
    end
    if not colIndex then return nil end

    -- Calculate column position
    local numCols = #Battle.COLUMN_LAYOUT
    local colWidth = screenWidth / numCols
    local colCenterX = colWidth * (colIndex - 0.5)

    -- Calculate card dimensions
    local cardW = colWidth * 0.7
    local cardH = cardW * 1.4

    -- Single card centered on center axis
    local centerY = screenHeight / 2
    local cardY = centerY - cardH / 2

    return { x = colCenterX, y = cardY + cardH / 2 }
end

function Battle.createColoredPowerBall(sourcePos, targetPos, power, color, onArrive)
    local ball = {
        x = sourcePos.x,
        y = sourcePos.y,
        sourceX = sourcePos.x,
        sourceY = sourcePos.y,
        targetX = targetPos.x,
        targetY = targetPos.y,
        power = power,
        progress = 0,
        onArrive = onArrive,
        color = color or {0.9, 0.7, 0.3},
    }
    table.insert(powerBalls, ball)
    return ball
end

function Battle.updatePowerBalls(dt)
    for i = #powerBalls, 1, -1 do
        local ball = powerBalls[i]
        local dx = ball.targetX - ball.sourceX
        local dy = ball.targetY - ball.sourceY
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance > 0 then
            ball.progress = ball.progress + (BALL_SPEED * dt) / distance
        else
            ball.progress = 1
        end

        if ball.progress >= 1 then
            ball.progress = 1
            ball.x = ball.targetX
            ball.y = ball.targetY
            if ball.onArrive then ball.onArrive(ball) end
            table.remove(powerBalls, i)
        else
            ball.x = ball.sourceX + dx * ball.progress
            ball.y = ball.sourceY + dy * ball.progress
        end
    end
end

local function drawMiniCard(unit, x, y, width, height)
    local rarity = unit.rarity or (unit.card and unit.card.rarity) or "common"
    local rc = getRarityColor(rarity)
    local pulse = 0.65 + 0.35 * math.sin(love.timer.getTime() * 2.1)

    love.graphics.setColor(rc[1], rc[2], rc[3], 0.14 + pulse * 0.06)
    love.graphics.rectangle("fill", x - 2, y - 2, width + 4, height + 4, 5)

    love.graphics.setColor(0.12, 0.12, 0.16, 0.96)
    love.graphics.rectangle("fill", x, y, width, height, 4)
    love.graphics.setColor(rc[1], rc[2], rc[3], 0.92)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 4)
    love.graphics.setLineWidth(1)

    local unitName = utf8Truncate(unit.name or "单位", 6)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(getFont(10))
    love.graphics.print(unitName, x + 5, y + 4)

    love.graphics.setColor(rc[1], rc[2], rc[3], 0.95)
    love.graphics.setFont(getFont(9))
    love.graphics.print(rarityLabel[rarity] or "C", x + width - 14, y + 4)

    love.graphics.setColor(0.86, 0.73, 0.28)
    love.graphics.setFont(getFont(8))
    love.graphics.print(string.format("S%.2f R%.2f I%.2f", unit.sendPower or 0, unit.recvPower or 0, unit.interceptPower or 0), x + 5, y + height - 16)
end

function Battle.startTurn()
    currentPhase = "ready"
    log(string.format("第%d回合 - %s行动", currentTurn, players[activePlayer].name))
end

local function transferToEnemyCommand(sender, laneIndex, packetPower, sourcePos)
    local defender = players[activePlayer == 1 and 2 or 1]
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local enemyCommandPos = getCommandPosition(defender.id, screenWidth, screenHeight)
    if not enemyCommandPos then return end

    local receiver = {
        name = defender.command and defender.command.name or "主将",
        recvPower = defender.command and defender.command.recvPower or 0.75,
        powerMod = 0,
        tags = defender.command and safeTags(defender.command.tags) or {},
    }

    local successRate = calcTransferSuccessRate(sender, receiver, nil)
    local success = math.random() <= successRate

    Battle.createColoredPowerBall(sourcePos, enemyCommandPos, packetPower, {0.9, 0.3, 0.2}, function(ball)
        if not success then
            log(string.format("第%d路突击被对方主将防住（%.0f%%）", laneIndex, successRate * 100))
            return
        end

        local finalPower = applyPowerModifier(ball.power, sender, receiver)
        local damage = math.max(1, math.floor(finalPower + 0.5))
        defender.commandHp = defender.commandHp - damage
        log(string.format("第%d路突击命中，造成%d点伤害", laneIndex, damage))
    end)
end

local function transferRearToCenter(sender, laneIndex, packetPower, sourcePos)
    local player = players[activePlayer]
    local defender = players[activePlayer == 1 and 2 or 1]
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local centerSlots = getRowSlots(player, Battle.ROW.CENTER)
    local targetSlot = chooseTargetByDistribution(sender, centerSlots)
    if not targetSlot then return end

    local receiver = targetSlot.unit
    local centerPos = getUnitPosition(player.id, Battle.ROW.CENTER, targetSlot.index, screenWidth, screenHeight)
    if not centerPos then return end

    local interceptor = findNearestEnemyInterceptor(defender, Battle.ROW.CENTER, targetSlot.index)
    local successRate = calcTransferSuccessRate(sender, receiver, interceptor)
    local success = math.random() <= successRate

    Battle.createColoredPowerBall(sourcePos, centerPos, packetPower, {0.85, 0.75, 0.4}, function(ball)
        if not success then
            log(string.format("%s 传给 %s 失败", sender.name or "后卫", receiver.name or "中军"))
            return
        end

        local nextPower = applyPowerModifier(ball.power, sender, receiver)
        local vanguardSlots = getRowSlots(player, Battle.ROW.VANGUARD)
        local nextSlot = chooseTargetByDistribution(receiver, vanguardSlots)
        if not nextSlot then return end

        local nextReceiver = nextSlot.unit
        local vanguardPos = getUnitPosition(player.id, Battle.ROW.VANGUARD, nextSlot.index, screenWidth, screenHeight)
        if not vanguardPos then return end

        local nextInterceptor = findNearestEnemyInterceptor(defender, Battle.ROW.REAR, nextSlot.index)
        local nextSuccessRate = calcTransferSuccessRate(receiver, nextReceiver, nextInterceptor)
        local nextSuccess = math.random() <= nextSuccessRate

        Battle.createColoredPowerBall(centerPos, vanguardPos, nextPower, {0.9, 0.6, 0.2}, function(cBall)
            if not nextSuccess then
                log(string.format("%s 传给 %s 失败", receiver.name or "中军", nextReceiver.name or "前锋"))
                return
            end

            local finalPower = applyPowerModifier(cBall.power, receiver, nextReceiver)
            transferToEnemyCommand(nextReceiver, nextSlot.index, finalPower, vanguardPos)
        end)
    end)
end

function Battle.startTransfer()
    currentPhase = "transfer"
    local player = players[activePlayer]
    local defender = players[activePlayer == 1 and 2 or 1]
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local commandPos = getCommandPosition(player.id, screenWidth, screenHeight)
    if not commandPos then
        log("错误：找不到主将位置，回合自动结束")
        currentPhase = "waiting"
        pendingTurnDelay = 0
        return
    end

    local commandNode = {
        name = player.command and player.command.name or "主将",
        sendPower = player.command and player.command.sendPower or 0.72,
        recvPower = player.command and player.command.recvPower or 0.78,
        interceptPower = player.command and player.command.interceptPower or 0.16,
        powerMod = player.command and player.command.powerMod or 0,
        tags = player.command and safeTags(player.command.tags) or {},
    }

    local totalPower = math.max(1, math.floor(player.basePowerGeneration or 1))
    log(string.format("%s 发起传递，本回合能量 %d", player.name, totalPower))

    for packetId = 1, totalPower do
        local rearSlots = getRowSlots(player, Battle.ROW.REAR)
        local rearTarget = chooseTargetByDistribution(commandNode, rearSlots)

        if rearTarget then
            local rearPos = getUnitPosition(player.id, Battle.ROW.REAR, rearTarget.index, screenWidth, screenHeight)
            if rearPos then
                local receiver = rearTarget.unit
                local interceptor = findNearestEnemyInterceptor(defender, Battle.ROW.VANGUARD, rearTarget.index)
                local successRate = calcTransferSuccessRate(commandNode, receiver, interceptor)
                local success = math.random() <= successRate

                Battle.createColoredPowerBall(commandPos, rearPos, 1, {0.9, 0.7, 0.3}, function(ball)
                    if not success then
                        log(string.format("第%d股能量在后卫线路被拦截", packetId))
                        return
                    end
                    local nextPower = applyPowerModifier(ball.power, commandNode, receiver)
                    transferRearToCenter(receiver, rearTarget.index, nextPower, rearPos)
                end)
            end
        end
    end

    if isTestMode() then
        print(string.format("[TEST] transfer started, balls=%d", #powerBalls))
    end
end

function Battle.checkTransferComplete()
    if currentPhase ~= "transfer" then return end
    if #powerBalls > 0 then return end

    local defender = players[activePlayer == 1 and 2 or 1]
    if defender.commandHp <= 0 then
        log(string.format("%s 的主将被击破", defender.name))
        log(string.format("%s 获胜", players[activePlayer].name))
        currentPhase = "victory"
        return
    end

    log(string.format("%s 主将剩余生命：%d", defender.name, defender.commandHp))
    currentPhase = "waiting"
    pendingTurnDelay = 1.0
end

function Battle.endTurn()
    currentPhase = "waiting"
    activePlayer = (activePlayer == 1) and 2 or 1
    if activePlayer == 1 then
        currentTurn = currentTurn + 1
    end
    Battle.startTurn()
end

function Battle.setDeploymentData(data)
    deploymentData = data or {}
end

function Battle.init()
    loadChineseFonts()

    -- Load CardRenderer for card drawing
    CardRenderer = require('src.cards.card_renderer')
    CardRenderer.init()

    -- Load background image
    local ok, img = pcall(love.graphics.newImage, "assets/images/backgrounds/bg_battle.png")
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

    local p1 = deploymentData and deploymentData.player1 or nil
    local p2 = ensureOpponentData()

    players = {
        createPlayerFromDeployment(1, "玩家", p1) or createDefaultPlayer(1, "玩家"),
        createPlayerFromDeployment(2, "电脑", p2) or createDefaultPlayer(2, "电脑"),
    }

    if not players[1].command then
        players[1] = createDefaultPlayer(1, "玩家")
    end
    if not players[2].command then
        players[2] = createDefaultPlayer(2, "电脑")
    end

    currentTurn = 1
    activePlayer = 1
    currentPhase = "idle"

    battleLog = {}
    powerBalls = {}
    pendingTurnDelay = nil

    log("战斗开始")
    Battle.startTurn()
end

function Battle.update(dt)
    Battle.updatePowerBalls(dt)
    Battle.checkTransferComplete()

    if pendingTurnDelay then
        pendingTurnDelay = pendingTurnDelay - dt
        if pendingTurnDelay <= 0 then
            pendingTurnDelay = nil
            Battle.endTurn()
        end
    end
end

local function drawPowerBalls()
    for _, ball in ipairs(powerBalls) do
        local r, g, b = ball.color[1], ball.color[2], ball.color[3]

        love.graphics.setColor(r, g, b, 0.3)
        love.graphics.circle("fill", ball.x, ball.y, BALL_RADIUS * 2)

        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.circle("fill", ball.x, ball.y, BALL_RADIUS)

        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.circle("fill", ball.x - 2, ball.y - 2, BALL_RADIUS * 0.4)

        love.graphics.setColor(1, 1, 1)
        local font10 = getFont(10)
        love.graphics.setFont(font10)
        local text = tostring(math.floor(ball.power + 0.5))
        local textWidth = font10:getWidth(text)
        love.graphics.print(text, ball.x - textWidth / 2, ball.y - 18)
    end
end

function Battle.drawFormation(screenWidth, screenHeight)
    local numCols = #Battle.COLUMN_LAYOUT
    local colWidth = screenWidth / numCols
    local centerY = screenHeight / 2

    -- Card dimensions
    local cardW = colWidth * 0.7
    local cardH = cardW * 1.4
    local cardGap = 5

    -- Draw each column
    for colIndex, col in ipairs(Battle.COLUMN_LAYOUT) do
        local player = players[col.player]
        local colCenterX = colWidth * (colIndex - 0.5)
        local cardX = colCenterX - cardW / 2

        -- Draw column label
        love.graphics.setColor(col.player == 1 and 0.3 or 0.6, col.player == 1 and 0.6 or 0.3, 0.4)
        love.graphics.setFont(getFont(12))
        local labelText = col.label
        local labelW = getFont(12):getWidth(labelText)
        love.graphics.print(labelText, colCenterX - labelW / 2, 70)

        if col.rowType == Battle.ROW.COMMAND then
            -- Draw command card - centered around center axis
            local command = player.command
            if command and command.card then
                -- Single card centered on center axis
                local cardY = centerY - cardH / 2

                -- Draw card using CardRenderer
                CardRenderer.drawCard(command.card, cardX, cardY, cardW, cardH, {
                    selected = false,
                    time = love.timer.getTime()
                })

                -- Draw HP bar below the card
                local hpBarY = cardY + cardH + 3
                local hpBarW = cardW - 20
                local hpBarH = 10
                local hpBarX = cardX + 10

                love.graphics.setColor(0.15, 0.15, 0.18, 0.9)
                love.graphics.rectangle("fill", hpBarX, hpBarY, hpBarW, hpBarH, 3)

                local hpRatio = math.max(0, math.min(1, player.commandHp / player.maxCommandHp))
                love.graphics.setColor(0.9, 0.3, 0.25, 0.9)
                love.graphics.rectangle("fill", hpBarX, hpBarY, hpBarW * hpRatio, hpBarH, 3)

                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.setFont(getFont(8))
                local hpText = player.commandHp .. "/" .. player.maxCommandHp
                local hpTextW = getFont(8):getWidth(hpText)
                love.graphics.print(hpText, hpBarX + (hpBarW - hpTextW) / 2, hpBarY + 1)
            end
        else
            -- Draw regular units - symmetrically distributed around center axis
            local units = player.units[col.rowType] or {}
            local rowUnits = {}
            for i, unit in ipairs(units) do
                if unit then
                    table.insert(rowUnits, { unit = unit, index = i })
                end
            end

            local numUnits = #rowUnits
            if numUnits > 0 then
                -- Calculate total height of all cards including gaps
                local totalHeight = numUnits * cardH + math.max(0, numUnits - 1) * cardGap

                -- Center the stack around the center axis
                -- startY is the top of the first card
                local startY = centerY - totalHeight / 2

                for i, unitData in ipairs(rowUnits) do
                    local unit = unitData.unit
                    -- Cards arranged from top to bottom, centered around center axis
                    local cardY = startY + (i - 1) * (cardH + cardGap)

                    if unit.card then
                        CardRenderer.drawCard(unit.card, cardX, cardY, cardW, cardH, {
                            selected = false,
                            time = love.timer.getTime()
                        })
                    else
                        -- Fallback: draw placeholder
                        love.graphics.setColor(0.15, 0.15, 0.2, 0.8)
                        love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 5)
                        love.graphics.setColor(0.4, 0.4, 0.5)
                        love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 5)
                        love.graphics.setColor(0.6, 0.6, 0.6)
                        love.graphics.setFont(getFont(12))
                        love.graphics.print(unit.name or "单位", cardX + 10, cardY + 10)
                    end
                end
            end
        end
    end

    -- Draw center line (battle line)
    love.graphics.setColor(0.9, 0.75, 0.3, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.line(0, centerY, screenWidth, centerY)
    love.graphics.setLineWidth(1)

    drawPowerBalls()
end

function Battle.returnToMenu()
    if not GameState then
        GameState = require('src.game.gamestate')
    end
    GameState.switch("MENU")
end

function Battle.drawButtons(screenWidth, screenHeight)
    local buttons = {}

    if currentPhase == "ready" then
        table.insert(buttons, {
            text = "开始回合",
            x = screenWidth / 2 - 60,
            y = screenHeight - 100,
            width = 120,
            height = 50,
            imgIdx = 1,
            onClick = function() Battle.startTransfer() end,
        })
    elseif currentPhase == "victory" then
        table.insert(buttons, {
            text = "返回主菜单",
            x = screenWidth / 2 - 70,
            y = screenHeight - 100,
            width = 140,
            height = 50,
            imgIdx = 3,
            onClick = function() Battle.returnToMenu() end,
        })
    end

    local font16 = getFont(16)
    love.graphics.setFont(font16)
    local mx, my = love.mouse.getPosition()

    for _, btn in ipairs(buttons) do
        local hovered = mx >= btn.x and mx <= btn.x + btn.width and my >= btn.y and my <= btn.y + btn.height

        -- Draw button with image or fallback
        local img = buttonImgs[btn.imgIdx or 1]
        if img then
            local imgW, imgH = img:getWidth(), img:getHeight()
            local scale = math.max(btn.width / imgW, btn.height / imgH)
            local drawW, drawH = imgW * scale, imgH * scale
            local offsetX, offsetY = (drawW - btn.width) / 2, (drawH - btn.height) / 2
            love.graphics.setColor(1, 1, 1, hovered and 1 or 0.85)
            love.graphics.draw(img, btn.x - offsetX, btn.y - offsetY, 0, scale, scale)
        else
            if hovered then
                love.graphics.setColor(0.4, 0.6, 0.8)
            else
                love.graphics.setColor(0.3, 0.4, 0.5)
            end
            love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5)

            love.graphics.setColor(0.6, 0.7, 0.8)
            love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5)
        end

        love.graphics.setColor(1, 1, 1)
        local textWidth = font16:getWidth(btn.text)
        love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2, btn.y + 10)

        btn.clickArea = { x = btn.x, y = btn.y, width = btn.width, height = btn.height }
    end

    Battle.currentButtons = buttons
end

function Battle.drawLog(screenWidth, screenHeight)
    local logX = screenWidth - 300
    local logY = screenHeight - 220
    local logHeight = 200

    love.graphics.setColor(0.15, 0.15, 0.2, 0.9)
    love.graphics.rectangle("fill", logX, logY, 280, logHeight)

    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", logX, logY, 280, logHeight)

    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(getFont(14))
    love.graphics.print("战斗日志", logX + 10, logY + 5)

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setFont(getFont(12))

    local lineHeight = 16
    local maxLines = math.floor((logHeight - 30) / lineHeight)
    local startIdx = math.max(1, #battleLog - maxLines + 1)

    for i = startIdx, #battleLog do
        local line = battleLog[i]
        local y = logY + 25 + (i - startIdx) * lineHeight
        love.graphics.print(line, logX + 10, y)
    end
end

function Battle.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw background image
    if backgroundImage then
        love.graphics.setColor(1, 1, 1, 1)
        local scale = math.max(screenWidth / backgroundImage:getWidth(), screenHeight / backgroundImage:getHeight())
        local drawW = backgroundImage:getWidth() * scale
        local drawH = backgroundImage:getHeight() * scale
        local offsetX = (drawW - screenWidth) / 2
        local offsetY = (drawH - screenHeight) / 2
        love.graphics.draw(backgroundImage, -offsetX, -offsetY, 0, scale, scale)
    else
        love.graphics.setColor(0.1, 0.1, 0.15)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    end

    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(getFont(24))
    love.graphics.print("卡牌战争 - 第" .. currentTurn .. "回合", 20, 20)

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(getFont(16))
    love.graphics.print("当前阶段: " .. (phaseText[currentPhase] or currentPhase), 20, 50)
    love.graphics.print("当前玩家: " .. players[activePlayer].name, 20, 70)

    Battle.drawFormation(screenWidth, screenHeight)
    Battle.drawButtons(screenWidth, screenHeight)
    Battle.drawLog(screenWidth, screenHeight)
end

function Battle.mousepressed(x, y, button)
    if button ~= 1 then return end

    if Battle.currentButtons then
        for _, btn in ipairs(Battle.currentButtons) do
            if btn.clickArea and btn.onClick then
                if x >= btn.clickArea.x and x <= btn.clickArea.x + btn.clickArea.width
                   and y >= btn.clickArea.y and y <= btn.clickArea.y + btn.clickArea.height then
                    btn.onClick()
                    return
                end
            end
        end
    end
end

function Battle.exit()
    print("退出战斗场景")
end

return Battle
