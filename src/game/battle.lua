--[[
    鍗＄墝鎴樹簤 - 鎴樻枟绯荤粺
    鏍稿績鏈哄埗锛?鎺?1鍗曚綅闃靛瀷锛屾垬鍔涘眰灞備紶閫掓敾鍑诲ぇ钀?--]]

local Battle = {}

-- 娓告垙鐘舵€佺鐞嗗櫒锛堝欢杩熷姞杞斤級
local GameState = nil

-- ============================================================================
-- 娓告垙甯搁噺
-- ============================================================================

Battle.ROW = {
    COMMAND = 1,    -- 澶ц惀
    VANGUARD = 2,   -- 鍏堥攱
    CENTER = 3,     -- 涓啗
    REAR = 4        -- 娈垮悗
}

Battle.ROW_NAME = {
    [1] = "澶ц惀",
    [2] = "鍏堥攱",
    [3] = "涓啗",
    [4] = "娈垮悗"
}

Battle.UNITS_PER_ROW = {
    [1] = 1,  -- 澶ц惀鍙湁1涓崟浣?    [2] = 3,  -- 鍏堥攱3涓?    [3] = 3,  -- 涓啗3涓?    [4] = 3   -- 娈垮悗3涓?}

-- 闃靛瀷浜ら敊鎺掑垪椤哄簭锛堜粠宸辨柟澶ц惀鍒版晫鏂瑰ぇ钀ワ級
-- { 鐜╁, 鎺掔被鍨?}
Battle.FORMATION_ORDER = {
    {1, Battle.ROW.COMMAND},   -- A澶ц惀
    {2, Battle.ROW.VANGUARD},  -- B鍏堥攱
    {1, Battle.ROW.REAR},      -- A娈垮悗
    {2, Battle.ROW.CENTER},    -- B涓啗
    {1, Battle.ROW.CENTER},    -- A涓啗
    {2, Battle.ROW.REAR},      -- B娈垮悗
    {1, Battle.ROW.VANGUARD},  -- A鍏堥攱
    {2, Battle.ROW.COMMAND}    -- B澶ц惀
}

-- ============================================================================
-- 娓告垙鐘舵€?-- ============================================================================

local players = {}          -- 涓や釜鐜╁鐨勬暟鎹?local currentTurn = 1       -- 褰撳墠鍥炲悎鏁?local currentPhase = "idle" -- 褰撳墠闃舵: idle/generate/deploy/transfer/attack
local activePlayer = 1      -- 褰撳墠琛屽姩鐜╁ (1 鎴?2)
local battleLog = {}        -- 鎴樻枟鏃ュ織

-- 涓枃瀛椾綋
local chineseFont = {}

-- 甯冮樀鏁版嵁
local deploymentData = {}

-- 鎴樺姏鐞冨姩鐢?local powerBalls = {}  -- 瀛樺偍鎵€鏈夋鍦ㄧЩ鍔ㄧ殑鎴樺姏鐞?local BALL_SPEED = 200  -- 鐞冪Щ鍔ㄩ€熷害锛堝儚绱?绉掞級
local BALL_RADIUS = 6   -- 鐞冨崐寰?
local rarityLabel = {
    common = "C",
    uncommon = "U",
    rare = "R",
    legendary = "L"
}

local function getRarityColor(rarity)
    local colors = {
        common = {0.7, 0.7, 0.7},
        uncommon = {0.2, 0.8, 0.2},
        rare = {0.2, 0.5, 1},
        legendary = {1, 0.8, 0.2}
    }
    return colors[rarity] or colors.common
end

local function getUnitRarity(unit)
    if unit.rarity then return unit.rarity end
    if unit.card and unit.card.rarity then return unit.card.rarity end
    return "common"
end

local function drawMiniCard(unit, x, y, width, height, selected)
    local rarity = getUnitRarity(unit)
    local rc = getRarityColor(rarity)
    local pulse = 0.65 + 0.35 * math.sin(love.timer.getTime() * 2.1)

    love.graphics.setColor(rc[1], rc[2], rc[3], 0.14 + pulse * 0.06)
    love.graphics.rectangle("fill", x - 2, y - 2, width + 4, height + 4, 5)

    love.graphics.setColor(0.12, 0.12, 0.16, 0.96)
    love.graphics.rectangle("fill", x, y, width, height, 4)
    love.graphics.setColor(rc[1], rc[2], rc[3], selected and 1 or 0.92)
    love.graphics.setLineWidth(selected and 3 or 2)
    love.graphics.rectangle("line", x, y, width, height, 4)
    love.graphics.setLineWidth(1)

    local artX, artY = x + 4, y + 18
    local artW, artH = width - 8, math.max(16, math.floor(height * 0.36))
    love.graphics.setColor(0.16, 0.17, 0.22, 1)
    love.graphics.rectangle("fill", artX, artY, artW, artH, 3)
    love.graphics.setColor(rc[1], rc[2], rc[3], 0.25)
    love.graphics.rectangle("fill", artX + 2, artY + 2, artW - 4, artH - 4, 2)

    local unitName = unit.name or (unit.card and unit.card.name) or "Unit"
    if #unitName > 8 then
        unitName = string.sub(unitName, 1, 7) .. "."
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(chineseFont[10] or love.graphics.newFont(10))
    love.graphics.print(unitName, x + 5, y + 4)

    love.graphics.setColor(rc[1], rc[2], rc[3], 0.95)
    love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
    love.graphics.print(rarityLabel[rarity] or "C", x + width - 14, y + 4)

    love.graphics.setColor(0.86, 0.73, 0.28)
    love.graphics.setFont(chineseFont[8] or love.graphics.newFont(8))
    love.graphics.print(string.format("S%.2f R%.2f I%.2f", unit.sendPower or 0, unit.recvPower or 0, unit.interceptPower or 0), x + 5, y + height - 16)
end

local function clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function safeTagTable(tags)
    if type(tags) == "table" then return tags end
    return {}
end

local function normalizeUnitTransferStats(unit, rowType)
    unit.sendPower = unit.sendPower or unit.send or 0.55
    unit.recvPower = unit.recvPower or unit.recv or 0.55
    unit.interceptPower = unit.interceptPower or unit.intercept or 0.12
    unit.powerMod = unit.powerMod or unit.transferMod or 0
    unit.tags = safeTagTable(unit.tags)

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

local function calcTagSynergy(tagsA, tagsB)
    local a = safeTagTable(tagsA)
    local b = safeTagTable(tagsB)
    local score = 0
    if a.dynasty and b.dynasty and a.dynasty == b.dynasty then score = score + 0.04 end
    if a.surname and b.surname and a.surname == b.surname then score = score + 0.03 end
    if a.origin and b.origin and a.origin == b.origin then score = score + 0.03 end
    return score
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
        local tagBonus = calcTagSynergy(sender.tags, unit.tags)
        local w = 1 + (unit.recvPower or 0.5) * 1.2 + tagBonus * 5 + (unit.powerMod or 0) * 0.6
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
    if not rowType then return nil end
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

-- ============================================================================
-- 鍒濆鍖?-- ============================================================================

-- 璁剧疆甯冮樀鏁版嵁
function Battle.setDeploymentData(data)
    deploymentData = data or {}
end

function Battle.init()
    print("鍒濆鍖栨垬鏂?..")
    
    -- 鍔犺浇瀛椾綋
    loadChineseFonts()
    
    -- 浣跨敤甯冮樀鏁版嵁鎴栧垱寤洪粯璁ょ帺瀹?    if deploymentData and deploymentData.player1 then
        -- 浣跨敤鐜╁甯冮樀
        players = {
            Battle.createPlayerFromDeployment(1, "鐜╁", deploymentData.player1),
            Battle.createPlayerFromDeployment(2, "鏁屼汉", deploymentData.player2 or nil)
        }
    else
        -- 鍒涘缓榛樿鐜╁
        players = {
            Battle.createPlayer(1, "鐜╁"),
            Battle.createPlayer(2, "鏁屼汉")
        }
    end
    
    currentTurn = 1
    currentPhase = "generate"
    activePlayer = 1
    battleLog = {}
    
    addLog("鎴樻枟寮€濮嬶紒")
    addLog("绗?" .. currentTurn .. " 鍥炲悎 - " .. players[activePlayer].name .. " 鐨勮繘鏀诲洖鍚?)
    
    -- 寮€濮嬬涓€鍥炲悎
    Battle.startTurn()
end

-- 浠庡竷闃垫暟鎹垱寤虹帺瀹?
function Battle.createPlayerFromDeployment(id, name, deployData)
    local player = {
        id = id,
        name = name,
        command = nil,            -- 澶ц惀鍗＄墝
        units = {                 -- 鍚勫崟浣?            [Battle.ROW.COMMAND] = {},
            [Battle.ROW.VANGUARD] = {},
            [Battle.ROW.CENTER] = {},
            [Battle.ROW.REAR] = {}
        },
        basePowerGeneration = 5,  -- 鍩虹鎴樺姏鐢熸垚
        tempPower = 0,            -- 褰撳墠寰呭垎閰嶇殑鎴樺姏
        rowCounts = {             -- 姣忔帓鍗曚綅鏁伴噺
            [Battle.ROW.VANGUARD] = 3,
            [Battle.ROW.CENTER] = 3,
            [Battle.ROW.REAR] = 3
        }
    }
    
    if deployData then
        -- 璁剧疆澶ц惀
        if deployData.command then
            player.command = deployData.command
            player.commandHp = deployData.command.hp or 30
            player.maxCommandHp = deployData.command.hp or 30
            player.command.tags = safeTagTable(player.command.tags)
            player.command.sendPower = player.command.sendPower or 0.72
            player.command.recvPower = player.command.recvPower or 0.78
            player.command.interceptPower = player.command.interceptPower or 0.16
            player.command.powerMod = player.command.powerMod or 0
            -- 搴旂敤澶ц惀鑳藉姏
            for _, ability in ipairs(deployData.command.abilities or {}) do
                if ability.type == "bonus_generate" then
                    player.basePowerGeneration = player.basePowerGeneration + ability.value
                elseif ability.type == "bonus_transfer" then
                    player.command.powerMod = player.command.powerMod + (ability.value or 0)
                end
            end
        else
            player.commandHp = 30
            player.maxCommandHp = 30
        end
        
        -- 杈呭姪鍑芥暟锛氳绠楀垎鏁ｅ瓨鍌ㄨ〃涓殑瀹為檯鍗＄墝鏁伴噺
local function countCards(cardTable, maxIndex)
            local count = 0
            for i = 1, maxIndex do
                if cardTable[i] then count = count + 1 end
            end
            return count
        end
        
        -- 璁剧疆鍚勫崟浣嶏紙鏀寔鍒嗘暎瀛樺偍鐨勮〃锛?
local function processUnits(units, rowType)
            for i = 1, #units do
                if units[i] then
                    -- 纭繚鍗曚綅鏈夊繀瑕佺殑瀛楁
                    units[i].currentPower = units[i].currentPower or 0
                    units[i].maxPower = units[i].maxPower or 10
                    if not units[i].name then
                        units[i].name = units[i].card and units[i].card.name or (Battle.ROW_NAME[rowType] .. i)
                    end
                    normalizeUnitTransferStats(units[i], rowType)
                end
            end
            return units
        end
        
        if deployData.vanguard then
            player.units[Battle.ROW.VANGUARD] = processUnits(deployData.vanguard, Battle.ROW.VANGUARD)
            player.rowCounts[Battle.ROW.VANGUARD] = deployData.rowCounts and deployData.rowCounts.vanguard or 3
        end
        if deployData.center then
            player.units[Battle.ROW.CENTER] = processUnits(deployData.center, Battle.ROW.CENTER)
            player.rowCounts[Battle.ROW.CENTER] = deployData.rowCounts and deployData.rowCounts.center or 3
        end
        if deployData.rear then
            player.units[Battle.ROW.REAR] = processUnits(deployData.rear, Battle.ROW.REAR)
            player.rowCounts[Battle.ROW.REAR] = deployData.rowCounts and deployData.rowCounts.rear or 3
        end
    else
        -- 鍒涘缓闅忔満AI甯冮樀
        local Deployment = require('src.game.deployment')
        Deployment.init(id)
        Deployment.autoDeploy()
        local aiData = Deployment.getDeploymentResult()
        return Battle.createPlayerFromDeployment(id, name, aiData)
    end
    
    return player
end

-- 鍒涘缓榛樿鐜╁
function Battle.createPlayer(id, name)
    return {
        id = id,
        name = name,
        command = nil,
        commandHp = 30,
        maxCommandHp = 30,
        units = {
            [Battle.ROW.COMMAND] = {},
            [Battle.ROW.VANGUARD] = { 
                Battle.createUnit(Battle.ROW.VANGUARD, 1),
                Battle.createUnit(Battle.ROW.VANGUARD, 2),
                Battle.createUnit(Battle.ROW.VANGUARD, 3)
            },
            [Battle.ROW.CENTER] = { 
                Battle.createUnit(Battle.ROW.CENTER, 1),
                Battle.createUnit(Battle.ROW.CENTER, 2),
                Battle.createUnit(Battle.ROW.CENTER, 3)
            },
            [Battle.ROW.REAR] = { 
                Battle.createUnit(Battle.ROW.REAR, 1),
                Battle.createUnit(Battle.ROW.REAR, 2),
                Battle.createUnit(Battle.ROW.REAR, 3)
            }
        },
        basePowerGeneration = 5,
        tempPower = 0,
        rowCounts = {
            [Battle.ROW.VANGUARD] = 3,
            [Battle.ROW.CENTER] = 3,
            [Battle.ROW.REAR] = 3
        }
    }
end

function Battle.createUnit(row, index, card)
    if card then
        -- 浣跨敤鍗＄墝鏁版嵁鍒涘缓鍗曚綅
        local unit = {
            row = row,
            index = index,
            card = card,
            name = card.name,
            attack = card.attack or ((row == Battle.ROW.VANGUARD) and 1 or 0),
            defense = card.defense or 0,
            currentPower = 0,
            maxPower = 10,
            abilities = card.abilities or {},
            sendPower = card.sendPower,
            recvPower = card.recvPower,
            interceptPower = card.interceptPower,
            powerMod = card.powerMod,
            tags = safeTagTable(card.tags)
        }
        normalizeUnitTransferStats(unit, row)
        return unit
    else
        -- 鍒涘缓榛樿鍗曚綅
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
            tags = {}
        }
        normalizeUnitTransferStats(unit, row)
        return unit
    end
end

-- ============================================================================
-- 鎴樺姏鐞冨姩鐢?-- ============================================================================

-- 鍒涘缓鎴樺姏鐞?-- sourcePos: {x, y} 璧峰浣嶇疆
-- targetPos: {x, y} 鐩爣浣嶇疆  
-- power: 浠ｈ〃鐨勬垬鍔涘€?-- onArrive: 鍒拌揪鍥炶皟鍑芥暟
function Battle.createPowerBall(sourcePos, targetPos, power, onArrive)
    local ball = {
        x = sourcePos.x,
        y = sourcePos.y,
        sourceX = sourcePos.x,
        sourceY = sourcePos.y,
        targetX = targetPos.x,
        targetY = targetPos.y,
        power = power,
        progress = 0,  -- 0鍒?鐨勮繘搴?        onArrive = onArrive,
        color = {0.9, 0.7, 0.3}  -- 閲戣壊
    }
    table.insert(powerBalls, ball)
    return ball
end

-- 鏇存柊鎴樺姏鐞?
function Battle.updatePowerBalls(dt)
    local allArrived = true
    
    for i = #powerBalls, 1, -1 do
        local ball = powerBalls[i]
        
        -- 璁＄畻绉诲姩璺濈
        local dx = ball.targetX - ball.sourceX
        local dy = ball.targetY - ball.sourceY
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- 鏇存柊杩涘害
        if distance > 0 then
            ball.progress = ball.progress + (BALL_SPEED * dt) / distance
        else
            ball.progress = 1
        end
        
        if ball.progress >= 1 then
            -- 鍒拌揪鐩爣
            ball.progress = 1
            ball.x = ball.targetX
            ball.y = ball.targetY
            
            -- 鎵ц鍥炶皟
            if ball.onArrive then
                ball.onArrive(ball)
            end
            
            -- 绉婚櫎鐞?            table.remove(powerBalls, i)
        else
            -- 鏇存柊浣嶇疆锛堢嚎鎬ф彃鍊硷級
            ball.x = ball.sourceX + dx * ball.progress
            ball.y = ball.sourceY + dy * ball.progress
            allArrived = false
        end
    end
    
    return allArrived
end

-- 缁樺埗鎴樺姏鐞?
function Battle.drawPowerBalls()
    for _, ball in ipairs(powerBalls) do
        local r, g, b = ball.color[1], ball.color[2], ball.color[3]
        
        -- 缁樺埗鍏夋檿鏁堟灉锛堜娇鐢ㄧ悆鐨勯鑹诧級
        love.graphics.setColor(r, g, b, 0.3)
        love.graphics.circle("fill", ball.x, ball.y, BALL_RADIUS * 2)
        
        -- 缁樺埗鐞冧綋
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.circle("fill", ball.x, ball.y, BALL_RADIUS)
        
        -- 缁樺埗楂樺厜
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.circle("fill", ball.x - 2, ball.y - 2, BALL_RADIUS * 0.4)
        
        -- 缁樺埗鎴樺姏鏁板€?        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(chineseFont[10] or love.graphics.newFont(10))
        local text = tostring(ball.power)
        local textWidth = (chineseFont[10] or love.graphics.newFont(10)):getWidth(text)
        love.graphics.print(text, ball.x - textWidth/2, ball.y - 18)
    end
end

-- ============================================================================
-- 鍥炲悎娴佺▼
-- ============================================================================
function Battle.startTurn()
    local player = players[activePlayer]
    
    -- 闃舵 1: 鍑嗗闃舵锛岀瓑寰呯帺瀹剁偣鍑诲紑濮?    currentPhase = "ready"
    
    if TEST_MODE then
        roundCounter = roundCounter + 1
        print("[TEST] startTurn() called - roundCounter=" .. roundCounter .. ", activePlayer=" .. activePlayer .. ", turn=" .. currentTurn)
    end
    
    addLog(player.name .. " 鍥炲悎鍑嗗灏辩华锛岀偣鍑?寮€濮嬪洖鍚?鎵ц鎴樺姏浼犻€?)
end

-- 鐜╁鐐瑰嚮寮€濮嬪洖鍚堟寜閽?
function Battle.startRound()
    if TEST_MODE then
        print("[TEST] startRound() called - currentPhase=" .. tostring(currentPhase))
    end
    
    if currentPhase ~= "ready" then
        if TEST_MODE then
            print("[TEST] startRound() SKIPPED - not in ready phase")
        end
        return
    end
    
    local player = players[activePlayer]
    
    if TEST_MODE then
        print("[TEST] startRound() proceeding for player " .. activePlayer)
    end
    
    -- 寮€濮嬩紶閫掗摼锛堝ぇ钀モ啋娈垮悗鈫掍腑鍐涒啋鍏堥攱鈫掓晫鏂瑰ぇ钀ワ級
        Battle.startTransfer()
end

function Battle.getUnitPosition(playerId, rowType, unitIndex, screenWidth, screenHeight)
    local startX = screenWidth / 2 - 200
    local startY = 120
    local rowHeight = 60
    local unitWidth = 100
    local unitGap = 10

    for i, formation in ipairs(Battle.FORMATION_ORDER) do
        if formation[1] == playerId and formation[2] == rowType then
            local y = startY + (i - 1) * rowHeight
            local units = players[playerId].units[rowType] or {}
            local slotIndexes = {}
            local maxCount = (players[playerId].rowCounts and players[playerId].rowCounts[rowType]) or #units
            for idx = 1, maxCount do
                if units[idx] then table.insert(slotIndexes, idx) end
            end

            local unitCount = #slotIndexes
            if unitCount == 0 then return nil end

            local rowWidth = unitCount * unitWidth + (unitCount - 1) * unitGap
            local rowStartX = startX + (400 - rowWidth) / 2

            local displayPos = nil
            for displayIndex, realIndex in ipairs(slotIndexes) do
                if realIndex == unitIndex then
                    displayPos = displayIndex
                    break
                end
            end

            if displayPos then
                local x = rowStartX + (displayPos - 1) * (unitWidth + unitGap)
                return {x = x + unitWidth / 2, y = y + rowHeight / 2}
            end
        end
    end

    return nil
end

function Battle.getCommandPosition(playerId, screenWidth, screenHeight)
    local startX = screenWidth / 2 - 200
    local startY = 120
    local rowHeight = 60

    for i, formation in ipairs(Battle.FORMATION_ORDER) do
        if formation[1] == playerId and formation[2] == Battle.ROW.COMMAND then
            local y = startY + (i - 1) * rowHeight
            return {x = startX + 200, y = y + rowHeight / 2}
        end
    end

    return nil
end

local transferChains = {}  -- 璺熻釜姣忚矾鐨勪紶閫掔姸鎬?
-- 鍒涘缓甯︽湁棰滆壊娓愬彉鐨勬垬鍔涚悆
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
        color = color or {0.9, 0.7, 0.3}  -- 榛樿閲戣壊
    }
    table.insert(powerBalls, ball)
    return ball
end

-- 寮€濮嬪畬鏁寸殑鎴樺姏浼犻€掗摼
-- 浼犻€掕矾绾? 澶ц惀 鈫?娈垮悗 鈫?涓啗 鈫?鍏堥攱 鈫?鏁屾柟澶ц惀
function Battle.startTransfer()
    currentPhase = "transfer"
    transferStartTime = love.timer.getTime()
    transferChains = {}  -- 閲嶇疆浼犻€掗摼鐘舵€?

    local player = players[activePlayer]
    local defender = players[activePlayer == 1 and 2 or 1]
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    if TEST_MODE then
        print("[TEST] startTransfer() called - phase set to transfer")
    end
    
    addLog("开始战力传递...")
    addLog(player.name .. "的大营正在生成战力...")
    
    local totalPower = math.max(0, math.floor(player.basePowerGeneration or 0))
    
    if TEST_MODE then
        print("[TEST] Player " .. activePlayer .. " totalPower=" .. totalPower .. ", defender HP=" .. defender.commandHp)
    end
    
    local commandPos = Battle.getCommandPosition(activePlayer, screenWidth, screenHeight)
    
    if not commandPos then
        print("[ERROR] Failed to get command position")
        addLog("[ERROR] 无法获取大营位置")
        Battle.endTurn()
        return
    end

    local commandNode = {
        name = player.command and player.command.name or "大营",
        sendPower = player.command and player.command.sendPower or 0.72,
        recvPower = player.command and player.command.recvPower or 0.78,
        interceptPower = player.command and player.command.interceptPower or 0.16,
        powerMod = player.command and player.command.powerMod or 0,
        tags = player.command and safeTagTable(player.command.tags) or {}
    }

    local function transferToEnemyCommand(sender, laneIndex, packetPower, sourcePos)
        local enemyCommandPos = Battle.getCommandPosition(activePlayer == 1 and 2 or 1, screenWidth, love.graphics.getHeight())
        if not enemyCommandPos then return end

        local receiver = {
            name = defender.command and defender.command.name or "大营",
            recvPower = defender.command and defender.command.recvPower or 0.75,
            powerMod = 0,
            tags = defender.command and safeTagTable(defender.command.tags) or {}
        }
        local successRate = calcTransferSuccessRate(sender, receiver, nil)
        local success = math.random() <= successRate

        Battle.createColoredPowerBall(sourcePos, enemyCommandPos, packetPower, {0.9, 0.3, 0.2}, function(ball)
            if not success then
                addLog(string.format("第%d路未能突破敌方大营防线 (%.0f%%)", laneIndex, successRate * 100))
                return
            end
            local finalPower = applyPowerModifier(ball.power, sender, receiver)
            local damage = math.max(1, math.floor(finalPower + 0.5))
            defender.commandHp = defender.commandHp - damage
            addLog(string.format("第%d路传递成功，造成 %d 点战力打击！", laneIndex, damage))
        end)
    end

    local function transferRearToCenter(sender, laneIndex, packetPower, sourcePos)
        local centerSlots = getRowSlots(player, Battle.ROW.CENTER)
        local targetSlot = chooseTargetByDistribution(sender, centerSlots)
        if not targetSlot then return end
        local receiver = targetSlot.unit
        local centerPos = Battle.getUnitPosition(activePlayer, Battle.ROW.CENTER, targetSlot.index, screenWidth, love.graphics.getHeight())
        if not centerPos then return end

        local interceptor = findNearestEnemyInterceptor(defender, Battle.ROW.CENTER, targetSlot.index)
        local successRate = calcTransferSuccessRate(sender, receiver, interceptor)
        local success = math.random() <= successRate

        Battle.createColoredPowerBall(sourcePos, centerPos, packetPower, {0.85, 0.75, 0.4}, function(ball)
            if not success then
                addLog(string.format("%s -> %s 传递失败（敌方中军拦截）", sender.name or "单位", receiver.name or "单位"))
                return
            end
            local nextPower = applyPowerModifier(ball.power, sender, receiver)
            local vanguardSlots = getRowSlots(player, Battle.ROW.VANGUARD)
            local nextSlot = chooseTargetByDistribution(receiver, vanguardSlots)
            if not nextSlot then return end
            local nextReceiver = nextSlot.unit
            local vanguardPos = Battle.getUnitPosition(activePlayer, Battle.ROW.VANGUARD, nextSlot.index, screenWidth, love.graphics.getHeight())
            if not vanguardPos then return end
            local nextInterceptor = findNearestEnemyInterceptor(defender, Battle.ROW.REAR, nextSlot.index)
            local nextSuccessRate = calcTransferSuccessRate(receiver, nextReceiver, nextInterceptor)
            local nextSuccess = math.random() <= nextSuccessRate

            Battle.createColoredPowerBall(centerPos, vanguardPos, nextPower, {0.9, 0.6, 0.2}, function(cBall)
                if not nextSuccess then
                    addLog(string.format("%s -> %s 传递失败（敌方殿后拦截）", receiver.name or "单位", nextReceiver.name or "单位"))
                    return
                end
                local finalPower = applyPowerModifier(cBall.power, receiver, nextReceiver)
                transferToEnemyCommand(nextReceiver, nextSlot.index, finalPower, vanguardPos)
            end)
        end)
    end

    for packetId = 1, totalPower do
        local rearSlots = getRowSlots(player, Battle.ROW.REAR)
        local rearTarget = chooseTargetByDistribution(commandNode, rearSlots)
        if rearTarget then
            local rearPos = Battle.getUnitPosition(activePlayer, Battle.ROW.REAR, rearTarget.index, screenWidth, love.graphics.getHeight())
            if rearPos then
                local receiver = rearTarget.unit
                local interceptor = findNearestEnemyInterceptor(defender, Battle.ROW.VANGUARD, rearTarget.index)
                local successRate = calcTransferSuccessRate(commandNode, receiver, interceptor)
                local success = math.random() <= successRate
                Battle.createColoredPowerBall(commandPos, rearPos, 1, {0.9, 0.7, 0.3}, function(ball)
                    if not success then
                        addLog(string.format("战力单元#%d 首段传递失败（敌方先锋拦截）", packetId))
                        return
                    end
                    local nextPower = applyPowerModifier(ball.power, commandNode, receiver)
                    transferRearToCenter(receiver, rearTarget.index, nextPower, rearPos)
                end)
            end
        end
    end
    
    if TEST_MODE then
        print("[TEST] Total powerBalls created: " .. #powerBalls)
    end
end

-- 妫€鏌ヤ紶閫掑姩鐢绘槸鍚﹀畬鎴?
function Battle.checkTransferComplete()
    if TEST_MODE and #powerBalls > 0 then
        print("[TEST] checkTransferComplete() - " .. #powerBalls .. " balls still active")
    end
    
    if #powerBalls == 0 then
        local elapsed = love.timer.getTime() - transferStartTime
        if TEST_MODE then
            print("[TEST] All balls arrived! elapsed=" .. elapsed .. "s")
        end
        
        -- 鎵€鏈夌悆閮藉埌杈撅紝妫€鏌ユ槸鍚﹁儨鍒?        local defender = players[activePlayer == 1 and 2 or 1]
        if defender.commandHp <= 0 then
            addLog(defender.name .. " 澶ц惀琚敾鐮达紒")
            addLog(players[activePlayer].name .. " 鑾峰緱鑳滃埄锛?)
            currentPhase = "victory"
            if TEST_MODE then
                print("[TEST] VICTORY!")
            end
        else
            addLog(defender.name .. " 澶ц惀鍓╀綑鐢熷懡鍊? " .. defender.commandHp)
            -- 鍥炲悎缁撴潫锛屽垏鎹㈢帺瀹?            Battle.endTurn()
        end
    end
end

-- 鍥炲悎缁撴潫
function Battle.endTurn()
    if TEST_MODE then
        print("[TEST] endTurn() called - was player " .. activePlayer .. ", turn=" .. currentTurn)
    end
    
    -- 绔嬪嵆鍒囨崲鍒扮瓑寰呴樁娈碉紝闃叉閲嶅瑙﹀彂
    currentPhase = "waiting"
    
    -- 鍒囨崲鐜╁
    activePlayer = (activePlayer == 1) and 2 or 1
    
    -- 濡傛灉涓や釜鐜╁閮借鍔ㄨ繃锛岃繘鍏ヤ笅涓€鍥炲悎
    if activePlayer == 1 then
        currentTurn = currentTurn + 1
    end
    
    if TEST_MODE then
        print("[TEST] endTurn() - now player " .. activePlayer .. ", turn=" .. currentTurn)
    end
    
    addLog("---")
    addLog("绗?" .. currentTurn .. " 鍥炲悎 - " .. players[activePlayer].name .. " 鐨勮繘鏀诲洖鍚?)
    
    -- 寤惰繜鍚庡紑濮嬫柊鍥炲悎
    local timer = 0
    local oldUpdate = Battle.update
    Battle.update = function(dt)
        -- 寤惰繜鏈熼棿鍙洿鏂扮悆鍔ㄧ敾锛屼笉妫€鏌ュ畬鎴愮姸鎬?        Battle.updatePowerBalls(dt)
        
        timer = timer + dt
        if timer >= 1.0 then  -- 寤惰繜1绉?            if TEST_MODE then
                print("[TEST] Delay complete, calling startTurn()")
            end
            Battle.startTurn()
            Battle.update = oldUpdate
        end
    end
end

-- ============================================================================
-- 杈呭姪鍑芥暟
-- ============================================================================
function addLog(message)
    table.insert(battleLog, message)
    print(message)
    -- 闄愬埗鏃ュ織闀垮害
    if #battleLog > 50 then
        table.remove(battleLog, 1)
    end
end

function loadChineseFonts()
    -- 濡傛灉宸茬粡鍔犺浇杩囷紝鐩存帴杩斿洖
    if chineseFont[16] then return true end
    
    local fontPaths = {
        "assets/fonts/simhei.ttf",
        "assets/fonts/simkai.ttf",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/simkai.ttf",
    }
    
    for _, path in ipairs(fontPaths) do
        local success = pcall(function()
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
            print("Loaded font: " .. path)
            return true
        end
    end
    
    -- 濡傛灉閮藉け璐ヤ簡锛屼娇鐢ㄩ粯璁ゅ瓧浣擄紙鍙垱寤轰竴娆★級
    print("Warning: Could not load Chinese fonts, using default")
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

-- ============================================================================
-- 鏇存柊鍜岀粯鍒?-- ============================================================================

-- 璋冭瘯璁℃暟鍣?local debugFrameCounter = 0
function Battle.update(dt)
    -- 鏇存柊鎴樺姏鐞冨姩鐢?    Battle.updatePowerBalls(dt)
    
    -- 鍦ㄤ紶閫掗樁娈垫鏌ュ姩鐢绘槸鍚﹀畬鎴?    if currentPhase == "transfer" then
        Battle.checkTransferComplete()
    end
    
    -- 娴嬭瘯妯″紡锛氭瘡60甯ф墦鍗颁竴娆＄姸鎬?    if TEST_MODE then
        debugFrameCounter = debugFrameCounter + 1
        if debugFrameCounter >= 300 then  -- 姣?绉掞紙绾?00甯э級
            debugFrameCounter = 0
            print("[TEST] Status: turn=" .. currentTurn .. ", phase=" .. currentPhase .. ", activePlayer=" .. activePlayer .. ", powerBalls=" .. #powerBalls)
        end
    end
end

function Battle.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- 鑳屾櫙
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- 缁樺埗鏍囬
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[24])
    love.graphics.print("鍗＄墝鎴樹簤 - 绗?" .. currentTurn .. " 鍥炲悎", 20, 20)
    
    -- 缁樺埗褰撳墠闃舵
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(chineseFont[16])
    local phaseText = {
        idle = "绛夊緟涓?,
        ready = "鍑嗗灏辩华",
        waiting = "鍥炲悎鍒囨崲涓?,
        generate = "鐢熸垚闃舵",
        deploy = "閮ㄧ讲闃舵",
        transfer = "浼犻€掗樁娈?,
        attack = "鏀诲嚮闃舵",
        victory = "鎴樻枟缁撴潫"
    }
    love.graphics.print("褰撳墠闃舵: " .. (phaseText[currentPhase] or currentPhase), 20, 50)
    love.graphics.print("褰撳墠鐜╁: " .. players[activePlayer].name, 20, 70)
    
    -- 缁樺埗闃靛瀷
    Battle.drawFormation(screenWidth, screenHeight)
    
    -- 缁樺埗鎿嶄綔鎸夐挳
    Battle.drawButtons(screenWidth, screenHeight)
    
    -- 缁樺埗鎴樻枟鏃ュ織
    Battle.drawLog(screenWidth, screenHeight)
end

function Battle.drawFormation(screenWidth, screenHeight)
    local startX = screenWidth / 2 - 200
    local startY = 112
    local rowHeight = 66
    local unitWidth = 102
    local unitGap = 10

    for i, formation in ipairs(Battle.FORMATION_ORDER) do
        local playerId = formation[1]
        local rowType = formation[2]
        local player = players[playerId]
        local y = startY + (i - 1) * rowHeight

        if playerId == 1 then
            love.graphics.setColor(0.2, 0.4, 0.3, 0.28)
        else
            love.graphics.setColor(0.4, 0.2, 0.2, 0.28)
        end
        love.graphics.rectangle("fill", startX - 50, y, 500, rowHeight - 6)

        local units = player.units[rowType]
        local rowWidth = #units * unitWidth + (#units - 1) * unitGap
        local rowStartX = startX + (400 - rowWidth) / 2

        if rowType == Battle.ROW.COMMAND then
            local commandX = startX + 140
            local commandW = 120
            local commandH = rowHeight - 14
            local commandRarity = (player.command and player.command.rarity) or "rare"
            local rc = getRarityColor(commandRarity)
            local pulse = 0.65 + 0.35 * math.sin(love.timer.getTime() * 2)

            love.graphics.setColor(rc[1], rc[2], rc[3], 0.12 + pulse * 0.06)
            love.graphics.rectangle("fill", commandX - 2, y + 4, commandW + 4, commandH + 4, 6)
            love.graphics.setColor(0.14, 0.16, 0.22, 0.96)
            love.graphics.rectangle("fill", commandX, y + 6, commandW, commandH, 5)
            love.graphics.setColor(rc[1], rc[2], rc[3], 0.95)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", commandX, y + 6, commandW, commandH, 5)
            love.graphics.setLineWidth(1)

            local commandName = (player.command and player.command.name) or "Command"
            if #commandName > 9 then commandName = string.sub(commandName, 1, 8) .. "." end
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
            love.graphics.print(commandName, commandX + 8, y + 11)
            love.graphics.setColor(rc[1], rc[2], rc[3], 0.95)
            love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
            love.graphics.print((rarityLabel[commandRarity] or "R"), commandX + commandW - 16, y + 11)

            love.graphics.setColor(0.12, 0.13, 0.18, 1)
            love.graphics.rectangle("fill", commandX + 6, y + 27, commandW - 12, 14, 3)
            love.graphics.setColor(0.9, 0.25, 0.25, 0.9)
            local hpRatio = math.max(0, math.min(1, player.commandHp / player.maxCommandHp))
            love.graphics.rectangle("fill", commandX + 6, y + 27, (commandW - 12) * hpRatio, 14, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
            love.graphics.print(player.commandHp .. "/" .. player.maxCommandHp, commandX + 36, y + 29)
        else
            for j, unit in ipairs(units) do
                local x = rowStartX + (j - 1) * (unitWidth + unitGap)
                local selected = playerId == activePlayer and rowType == Battle.ROW.REAR and currentPhase == "deploy"
                drawMiniCard(unit, x, y + 4, unitWidth, rowHeight - 14, selected)
                unit.clickArea = {x = x, y = y + 4, width = unitWidth, height = rowHeight - 14}
            end
        end
    end

    for i, player in ipairs(players) do
        local y = (i == 1) and startY or (startY + 7 * rowHeight)
        local x = startX + 420

        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", x, y + 10, 150, 20)

        local hpPercent = player.commandHp / player.maxCommandHp
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.rectangle("fill", x, y + 10, 150 * hpPercent, 20)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(chineseFont[14])
        love.graphics.print(player.commandHp .. "/" .. player.maxCommandHp, x + 50, y + 12)
    end

    if currentPhase == "deploy" then
        local player = players[activePlayer]
        love.graphics.setColor(0.9, 0.7, 0.3)
        love.graphics.setFont(chineseFont[18])
        love.graphics.print("寰呭垎閰嶆垬鍔? " .. player.tempPower, 20, 100)
    end

    Battle.drawPowerBalls()
end

function Battle.returnToMenu()
    if not GameState then
        GameState = require('src.game.gamestate')
    end
    GameState.switch("MENU")
end

function Battle.drawButtons(screenWidth, screenHeight)
    local buttons = {}
    
    -- 鏍规嵁闃舵鏄剧ず涓嶅悓鎸夐挳
    if currentPhase == "ready" then
        -- 寮€濮嬪洖鍚堟寜閽?        table.insert(buttons, {
            text = "寮€濮嬪洖鍚?,
            x = screenWidth / 2 - 60,
            y = screenHeight - 100,
            width = 120,
            height = 50,
            onClick = function() Battle.startRound() end
        })
    elseif currentPhase == "victory" then
        -- 鎴樻枟缁撴潫鍚庣殑杩斿洖鎸夐挳
        table.insert(buttons, {
            text = "杩斿洖涓昏彍鍗?,
            x = screenWidth / 2 - 70,
            y = screenHeight - 100,
            width = 140,
            height = 50,
            onClick = function() Battle.returnToMenu() end
        })
    end
    
    -- 缁樺埗鎸夐挳
    love.graphics.setFont(chineseFont[16])
    for _, btn in ipairs(buttons) do
        -- 妫€娴嬫偓鍋?        local mx, my = love.mouse.getPosition()
        local hovered = mx >= btn.x and mx <= btn.x + btn.width
                        and my >= btn.y and my <= btn.y + btn.height
        
        -- 鎸夐挳鑳屾櫙
        if hovered then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.3, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5)
        
        -- 鎸夐挳杈规
        love.graphics.setColor(0.6, 0.7, 0.8)
        love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5)
        
        -- 鎸夐挳鏂囧瓧
        love.graphics.setColor(1, 1, 1)
        local textWidth = chineseFont[16]:getWidth(btn.text)
        love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2, btn.y + 10)
        
        -- 瀛樺偍鎸夐挳鐐瑰嚮鍖哄煙
        btn.clickArea = {x = btn.x, y = btn.y, width = btn.width, height = btn.height}
    end
    
    -- 淇濆瓨鎸夐挳鍒楄〃渚涚偣鍑绘娴嬩娇鐢?    Battle.currentButtons = buttons
end

function Battle.drawLog(screenWidth, screenHeight)
    local logX = screenWidth - 300
    local logY = screenHeight - 200
    local logHeight = 180
    
    -- 鏃ュ織鑳屾櫙
    love.graphics.setColor(0.15, 0.15, 0.2, 0.9)
    love.graphics.rectangle("fill", logX, logY, 280, logHeight)
    
    -- 鏃ュ織杈规
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", logX, logY, 280, logHeight)
    
    -- 鏃ュ織鏍囬
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[14] or love.graphics.newFont(14))
    love.graphics.print("鎴樻枟鏃ュ織", logX + 10, logY + 5)
    
    -- 鏃ュ織鍐呭
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
    
    local lineHeight = 16
    local maxLines = math.floor((logHeight - 30) / lineHeight)
    local startIdx = math.max(1, #battleLog - maxLines + 1)
    
    for i = startIdx, #battleLog do
        local line = battleLog[i]
        local y = logY + 25 + (i - startIdx) * lineHeight
        love.graphics.print(line, logX + 10, y)
    end
end

-- ============================================================================
-- 杈撳叆澶勭悊
-- ============================================================================
function Battle.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- 妫€鏌ユ寜閽偣鍑?    if Battle.currentButtons then
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
    
    -- 妫€鏌ユ鍚庡崟浣嶇偣鍑伙紙閮ㄧ讲闃舵锛?    if currentPhase == "deploy" then
        local player = players[activePlayer]
        for i, unit in ipairs(player.units[Battle.ROW.REAR]) do
            if unit.clickArea then
                if x >= unit.clickArea.x and x <= unit.clickArea.x + unit.clickArea.width
                   and y >= unit.clickArea.y and y <= unit.clickArea.y + unit.clickArea.height then
                    -- 鍚戣鍗曚綅閮ㄧ讲1鐐规垬鍔?                    Battle.deployPower(i, 1)
                    return
                end
            end
        end
    end
end

function Battle.exit()
    print("閫€鍑烘垬鏂?..")
end

return Battle




