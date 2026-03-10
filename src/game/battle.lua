--[[
    卡牌战争 - 战斗系统
    核心机制：4排11单位阵型，战力层层传递攻击大营
--]]

local Battle = {}

-- 游戏状态管理器（延迟加载）
local GameState = nil

-- ============================================================================
-- 游戏常量
-- ============================================================================

Battle.ROW = {
    COMMAND = 1,    -- 大营
    VANGUARD = 2,   -- 先锋
    CENTER = 3,     -- 中军
    REAR = 4        -- 殿后
}

Battle.ROW_NAME = {
    [1] = "大营",
    [2] = "先锋",
    [3] = "中军",
    [4] = "殿后"
}

Battle.UNITS_PER_ROW = {
    [1] = 1,  -- 大营只有1个单位
    [2] = 3,  -- 先锋3个
    [3] = 3,  -- 中军3个
    [4] = 3   -- 殿后3个
}

-- 阵型交错排列顺序（从己方大营到敌方大营）
-- { 玩家, 排类型 }
Battle.FORMATION_ORDER = {
    {1, Battle.ROW.COMMAND},   -- A大营
    {2, Battle.ROW.VANGUARD},  -- B先锋
    {1, Battle.ROW.REAR},      -- A殿后
    {2, Battle.ROW.CENTER},    -- B中军
    {1, Battle.ROW.CENTER},    -- A中军
    {2, Battle.ROW.REAR},      -- B殿后
    {1, Battle.ROW.VANGUARD},  -- A先锋
    {2, Battle.ROW.COMMAND}    -- B大营
}

-- ============================================================================
-- 游戏状态
-- ============================================================================

local players = {}          -- 两个玩家的数据
local currentTurn = 1       -- 当前回合数
local currentPhase = "idle" -- 当前阶段: idle/generate/deploy/transfer/attack
local activePlayer = 1      -- 当前行动玩家 (1 或 2)
local battleLog = {}        -- 战斗日志

-- 中文字体
local chineseFont = {}

-- 布阵数据
local deploymentData = {}

-- 战力球动画
local powerBalls = {}  -- 存储所有正在移动的战力球
local BALL_SPEED = 200  -- 球移动速度（像素/秒）
local BALL_RADIUS = 6   -- 球半径

-- ============================================================================
-- 初始化
-- ============================================================================

-- 设置布阵数据
function Battle.setDeploymentData(data)
    deploymentData = data or {}
end

function Battle.init()
    print("初始化战斗...")
    
    -- 加载字体
    loadChineseFonts()
    
    -- 使用布阵数据或创建默认玩家
    if deploymentData and deploymentData.player1 then
        -- 使用玩家布阵
        players = {
            Battle.createPlayerFromDeployment(1, "玩家", deploymentData.player1),
            Battle.createPlayerFromDeployment(2, "敌人", deploymentData.player2 or nil)
        }
    else
        -- 创建默认玩家
        players = {
            Battle.createPlayer(1, "玩家"),
            Battle.createPlayer(2, "敌人")
        }
    end
    
    currentTurn = 1
    currentPhase = "generate"
    activePlayer = 1
    battleLog = {}
    
    addLog("战斗开始！")
    addLog("第 " .. currentTurn .. " 回合 - " .. players[activePlayer].name .. " 的进攻回合")
    
    -- 开始第一回合
    Battle.startTurn()
end

-- 从布阵数据创建玩家
function Battle.createPlayerFromDeployment(id, name, deployData)
    local player = {
        id = id,
        name = name,
        command = nil,            -- 大营卡牌
        units = {                 -- 各单位
            [Battle.ROW.COMMAND] = {},
            [Battle.ROW.VANGUARD] = {},
            [Battle.ROW.CENTER] = {},
            [Battle.ROW.REAR] = {}
        },
        basePowerGeneration = 5,  -- 基础战力生成
        tempPower = 0,            -- 当前待分配的战力
        rowCounts = {             -- 每排单位数量
            [Battle.ROW.VANGUARD] = 3,
            [Battle.ROW.CENTER] = 3,
            [Battle.ROW.REAR] = 3
        }
    }
    
    if deployData then
        -- 设置大营
        if deployData.command then
            player.command = deployData.command
            player.commandHp = deployData.command.hp or 30
            player.maxCommandHp = deployData.command.hp or 30
            -- 应用大营能力
            for _, ability in ipairs(deployData.command.abilities or {}) do
                if ability.type == "bonus_generate" then
                    player.basePowerGeneration = player.basePowerGeneration + ability.value
                end
            end
        else
            player.commandHp = 30
            player.maxCommandHp = 30
        end
        
        -- 辅助函数：计算分散存储表中的实际卡牌数量
        local function countCards(cardTable, maxIndex)
            local count = 0
            for i = 1, maxIndex do
                if cardTable[i] then count = count + 1 end
            end
            return count
        end
        
        -- 设置各单位（支持分散存储的表）
        local function processUnits(units, rowType)
            for i = 1, #units do
                if units[i] then
                    -- 确保单位有必要的字段
                    units[i].currentPower = units[i].currentPower or 0
                    units[i].maxPower = units[i].maxPower or 10
                    if not units[i].name then
                        units[i].name = units[i].card and units[i].card.name or (Battle.ROW_NAME[rowType] .. i)
                    end
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
        -- 创建随机AI布阵
        local Deployment = require('src.game.deployment')
        Deployment.init(id)
        Deployment.autoDeploy()
        local aiData = Deployment.getDeploymentResult()
        return Battle.createPlayerFromDeployment(id, name, aiData)
    end
    
    return player
end

-- 创建默认玩家
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
        -- 使用卡牌数据创建单位
        return {
            row = row,
            index = index,
            card = card,
            name = card.name,
            attack = card.attack or ((row == Battle.ROW.VANGUARD) and 1 or 0),
            defense = card.defense or 0,
            currentPower = 0,
            maxPower = 10,
            abilities = card.abilities or {}
        }
    else
        -- 创建默认单位
        return {
            row = row,
            index = index,
            card = nil,
            name = Battle.ROW_NAME[row] .. index,
            attack = (row == Battle.ROW.VANGUARD) and 1 or 0,
            defense = 0,
            currentPower = 0,
            maxPower = 10,
            abilities = {}
        }
    end
end

-- ============================================================================
-- 战力球动画
-- ============================================================================

-- 创建战力球
-- sourcePos: {x, y} 起始位置
-- targetPos: {x, y} 目标位置  
-- power: 代表的战力值
-- onArrive: 到达回调函数
function Battle.createPowerBall(sourcePos, targetPos, power, onArrive)
    local ball = {
        x = sourcePos.x,
        y = sourcePos.y,
        sourceX = sourcePos.x,
        sourceY = sourcePos.y,
        targetX = targetPos.x,
        targetY = targetPos.y,
        power = power,
        progress = 0,  -- 0到1的进度
        onArrive = onArrive,
        color = {0.9, 0.7, 0.3}  -- 金色
    }
    table.insert(powerBalls, ball)
    return ball
end

-- 更新战力球
function Battle.updatePowerBalls(dt)
    local allArrived = true
    
    for i = #powerBalls, 1, -1 do
        local ball = powerBalls[i]
        
        -- 计算移动距离
        local dx = ball.targetX - ball.sourceX
        local dy = ball.targetY - ball.sourceY
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- 更新进度
        if distance > 0 then
            ball.progress = ball.progress + (BALL_SPEED * dt) / distance
        else
            ball.progress = 1
        end
        
        if ball.progress >= 1 then
            -- 到达目标
            ball.progress = 1
            ball.x = ball.targetX
            ball.y = ball.targetY
            
            -- 执行回调
            if ball.onArrive then
                ball.onArrive(ball)
            end
            
            -- 移除球
            table.remove(powerBalls, i)
        else
            -- 更新位置（线性插值）
            ball.x = ball.sourceX + dx * ball.progress
            ball.y = ball.sourceY + dy * ball.progress
            allArrived = false
        end
    end
    
    return allArrived
end

-- 绘制战力球
function Battle.drawPowerBalls()
    for _, ball in ipairs(powerBalls) do
        local r, g, b = ball.color[1], ball.color[2], ball.color[3]
        
        -- 绘制光晕效果（使用球的颜色）
        love.graphics.setColor(r, g, b, 0.3)
        love.graphics.circle("fill", ball.x, ball.y, BALL_RADIUS * 2)
        
        -- 绘制球体
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.circle("fill", ball.x, ball.y, BALL_RADIUS)
        
        -- 绘制高光
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.circle("fill", ball.x - 2, ball.y - 2, BALL_RADIUS * 0.4)
        
        -- 绘制战力数值
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(chineseFont[10] or love.graphics.newFont(10))
        local text = tostring(ball.power)
        local textWidth = (chineseFont[10] or love.graphics.newFont(10)):getWidth(text)
        love.graphics.print(text, ball.x - textWidth/2, ball.y - 18)
    end
end

-- ============================================================================
-- 回合流程
-- ============================================================================

function Battle.startTurn()
    local player = players[activePlayer]
    
    -- 阶段 1: 准备阶段，等待玩家点击开始
    currentPhase = "ready"
    
    if TEST_MODE then
        roundCounter = roundCounter + 1
        print("[TEST] startTurn() called - roundCounter=" .. roundCounter .. ", activePlayer=" .. activePlayer .. ", turn=" .. currentTurn)
    end
    
    addLog(player.name .. " 回合准备就绪，点击'开始回合'执行战力传递")
end

-- 玩家点击开始回合按钮
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
    
    -- 开始传递链（大营→殿后→中军→先锋→敌方大营）
    Battle.startTransfer()
end

-- 部署战力到殿后单位
-- 计算单位在屏幕上的位置
function Battle.getUnitPosition(playerId, rowType, unitIndex, screenWidth, screenHeight)
    local startX = screenWidth / 2 - 200
    local startY = 120
    local rowHeight = 60
    local unitWidth = 100
    local unitGap = 10
    
    -- 找到该单位在 FORMATION_ORDER 中的位置
    for i, formation in ipairs(Battle.FORMATION_ORDER) do
        if formation[1] == playerId and formation[2] == rowType then
            local y = startY + (i - 1) * rowHeight
            local units = players[playerId].units[rowType]
            local unitCount = #units
            local rowWidth = unitCount * unitWidth + (unitCount - 1) * unitGap
            local rowStartX = startX + (400 - rowWidth) / 2
            
            if unitIndex >= 1 and unitIndex <= unitCount then
                local x = rowStartX + (unitIndex - 1) * (unitWidth + unitGap)
                return {x = x + unitWidth/2, y = y + rowHeight/2}  -- 返回中心点
            end
        end
    end
    return nil
end

-- 获取大营位置
function Battle.getCommandPosition(playerId, screenWidth, screenHeight)
    -- 大营是单独存储的，不在 units 表中，需要特殊处理
    local startX = screenWidth / 2 - 200
    local startY = 120
    local rowHeight = 60
    
    -- 找到大营在 FORMATION_ORDER 中的位置
    for i, formation in ipairs(Battle.FORMATION_ORDER) do
        if formation[1] == playerId and formation[2] == Battle.ROW.COMMAND then
            local y = startY + (i - 1) * rowHeight
            -- 大营在行中央
            return {x = startX + 200, y = y + rowHeight/2}
        end
    end
    return nil
end

-- 战力传递链状态
local transferChains = {}  -- 跟踪每路的传递状态

-- 创建带有颜色渐变的战力球
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
        color = color or {0.9, 0.7, 0.3}  -- 默认金色
    }
    table.insert(powerBalls, ball)
    return ball
end

-- 开始完整的战力传递链
-- 传递路线: 大营 → 殿后 → 中军 → 先锋 → 敌方大营
function Battle.startTransfer()
    currentPhase = "transfer"
    transferStartTime = love.timer.getTime()
    transferChains = {}  -- 重置传递链状态
    
    -- 先获取玩家数据
    local player = players[activePlayer]
    local defender = players[activePlayer == 1 and 2 or 1]
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    if TEST_MODE then
        print("[TEST] startTransfer() called - phase set to transfer")
    end
    
    addLog("开始战力传递...")
    addLog(player.name .. "的大营正在生成战力...")
    
    -- 总战力（大营生成的）
    local totalPower = player.basePowerGeneration
    
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
    
    -- 为3路分别创建传递链
    -- 每路：大营 → 殿后单位 → 中军单位 → 先锋单位 → 敌方大营
    for lane = 1, 3 do
        transferChains[lane] = { active = true, currentStage = "command" }
        
        -- 分配战力（尽量平均分配到3路）
        local lanePower = math.floor(totalPower / 3) + (lane <= (totalPower % 3) and 1 or 0)
        
        if lanePower > 0 then
            -- 阶段1: 大营 → 殿后
            local rearPos = Battle.getUnitPosition(activePlayer, Battle.ROW.REAR, lane, screenWidth, screenHeight)
            
            if rearPos then
                -- 大营发出金色球
                Battle.createColoredPowerBall(commandPos, rearPos, lanePower, {0.9, 0.7, 0.3}, function(ball)
                    -- 阶段2: 殿后 → 中军
                    local centerPos = Battle.getUnitPosition(activePlayer, Battle.ROW.CENTER, lane, screenWidth, screenHeight)
                    if centerPos then
                        -- 殿后发出淡金色球
                        Battle.createColoredPowerBall(rearPos, centerPos, ball.power, {0.85, 0.75, 0.4}, function(cBall)
                            -- 阶段3: 中军 → 先锋
                            local vanguardPos = Battle.getUnitPosition(activePlayer, Battle.ROW.VANGUARD, lane, screenWidth, screenHeight)
                            if vanguardPos then
                                -- 中军发出橙色球
                                Battle.createColoredPowerBall(centerPos, vanguardPos, cBall.power, {0.9, 0.6, 0.2}, function(vBall)
                                    -- 阶段4: 先锋 → 敌方大营
                                    local enemyCommandPos = Battle.getCommandPosition(activePlayer == 1 and 2 or 1, screenWidth, screenHeight)
                                    if enemyCommandPos then
                                        -- 先锋发出红色球（攻击）
                                        Battle.createColoredPowerBall(vanguardPos, enemyCommandPos, vBall.power, {0.9, 0.3, 0.2}, function(aBall)
                                            -- 攻击敌方大营
                                            defender.commandHp = defender.commandHp - aBall.power
                                            addLog("第" .. lane .. "路造成 " .. aBall.power .. " 点伤害！")
                                            transferChains[lane].active = false
                                        end)
                                    else
                                        transferChains[lane].active = false
                                    end
                                end)
                            else
                                transferChains[lane].active = false
                            end
                        end)
                    else
                        transferChains[lane].active = false
                    end
                end)
            else
                transferChains[lane].active = false
            end
        else
            transferChains[lane].active = false
        end
    end
    
    if TEST_MODE then
        print("[TEST] Total powerBalls created: " .. #powerBalls)
    end
end

-- 检查传递动画是否完成
function Battle.checkTransferComplete()
    if TEST_MODE and #powerBalls > 0 then
        print("[TEST] checkTransferComplete() - " .. #powerBalls .. " balls still active")
    end
    
    if #powerBalls == 0 then
        local elapsed = love.timer.getTime() - transferStartTime
        if TEST_MODE then
            print("[TEST] All balls arrived! elapsed=" .. elapsed .. "s")
        end
        
        -- 所有球都到达，检查是否胜利
        local defender = players[activePlayer == 1 and 2 or 1]
        if defender.commandHp <= 0 then
            addLog(defender.name .. " 大营被攻破！")
            addLog(players[activePlayer].name .. " 获得胜利！")
            currentPhase = "victory"
            if TEST_MODE then
                print("[TEST] VICTORY!")
            end
        else
            addLog(defender.name .. " 大营剩余生命值: " .. defender.commandHp)
            -- 回合结束，切换玩家
            Battle.endTurn()
        end
    end
end

-- 回合结束
function Battle.endTurn()
    if TEST_MODE then
        print("[TEST] endTurn() called - was player " .. activePlayer .. ", turn=" .. currentTurn)
    end
    
    -- 立即切换到等待阶段，防止重复触发
    currentPhase = "waiting"
    
    -- 切换玩家
    activePlayer = (activePlayer == 1) and 2 or 1
    
    -- 如果两个玩家都行动过，进入下一回合
    if activePlayer == 1 then
        currentTurn = currentTurn + 1
    end
    
    if TEST_MODE then
        print("[TEST] endTurn() - now player " .. activePlayer .. ", turn=" .. currentTurn)
    end
    
    addLog("---")
    addLog("第 " .. currentTurn .. " 回合 - " .. players[activePlayer].name .. " 的进攻回合")
    
    -- 延迟后开始新回合
    local timer = 0
    local oldUpdate = Battle.update
    Battle.update = function(dt)
        -- 延迟期间只更新球动画，不检查完成状态
        Battle.updatePowerBalls(dt)
        
        timer = timer + dt
        if timer >= 1.0 then  -- 延迟1秒
            if TEST_MODE then
                print("[TEST] Delay complete, calling startTurn()")
            end
            Battle.startTurn()
            Battle.update = oldUpdate
        end
    end
end

-- ============================================================================
-- 辅助函数
-- ============================================================================

function addLog(message)
    table.insert(battleLog, message)
    print(message)
    -- 限制日志长度
    if #battleLog > 50 then
        table.remove(battleLog, 1)
    end
end

function loadChineseFonts()
    -- 如果已经加载过，直接返回
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
    
    -- 如果都失败了，使用默认字体（只创建一次）
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
-- 更新和绘制
-- ============================================================================

-- 调试计数器
local debugFrameCounter = 0

function Battle.update(dt)
    -- 更新战力球动画
    Battle.updatePowerBalls(dt)
    
    -- 在传递阶段检查动画是否完成
    if currentPhase == "transfer" then
        Battle.checkTransferComplete()
    end
    
    -- 测试模式：每60帧打印一次状态
    if TEST_MODE then
        debugFrameCounter = debugFrameCounter + 1
        if debugFrameCounter >= 300 then  -- 每5秒（约300帧）
            debugFrameCounter = 0
            print("[TEST] Status: turn=" .. currentTurn .. ", phase=" .. currentPhase .. ", activePlayer=" .. activePlayer .. ", powerBalls=" .. #powerBalls)
        end
    end
end

function Battle.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- 背景
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- 绘制标题
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[24])
    love.graphics.print("卡牌战争 - 第 " .. currentTurn .. " 回合", 20, 20)
    
    -- 绘制当前阶段
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(chineseFont[16])
    local phaseText = {
        idle = "等待中",
        ready = "准备就绪",
        waiting = "回合切换中",
        generate = "生成阶段",
        deploy = "部署阶段",
        transfer = "传递阶段",
        attack = "攻击阶段",
        victory = "战斗结束"
    }
    love.graphics.print("当前阶段: " .. (phaseText[currentPhase] or currentPhase), 20, 50)
    love.graphics.print("当前玩家: " .. players[activePlayer].name, 20, 70)
    
    -- 绘制阵型
    Battle.drawFormation(screenWidth, screenHeight)
    
    -- 绘制操作按钮
    Battle.drawButtons(screenWidth, screenHeight)
    
    -- 绘制战斗日志
    Battle.drawLog(screenWidth, screenHeight)
end

function Battle.drawFormation(screenWidth, screenHeight)
    local startX = screenWidth / 2 - 200
    local startY = 120
    local rowHeight = 60
    local unitWidth = 100
    local unitGap = 10
    
    -- 绘制双方阵型
    for i, formation in ipairs(Battle.FORMATION_ORDER) do
        local playerId = formation[1]
        local rowType = formation[2]
        local player = players[playerId]
        local y = startY + (i - 1) * rowHeight
        
        -- 行背景
        if playerId == 1 then
            love.graphics.setColor(0.2, 0.4, 0.3, 0.3)  -- 玩家绿色
        else
            love.graphics.setColor(0.4, 0.2, 0.2, 0.3)  -- 敌人红色
        end
        love.graphics.rectangle("fill", startX - 50, y, 500, rowHeight - 5)
        
        -- 绘制该排的单位
        local units = player.units[rowType]
        local rowWidth = #units * unitWidth + (#units - 1) * unitGap
        local rowStartX = startX + (400 - rowWidth) / 2
        
        -- 如果是大营排，特殊处理（显示大营指挥官）
        if rowType == Battle.ROW.COMMAND then
            -- 大营单独显示在中央
            local commandX = startX + 150
            local commandWidth = 100
            
            -- 大营背景（更华丽的颜色）
            if playerId == 1 then
                love.graphics.setColor(0.4, 0.6, 0.5)  -- 玩家绿色（更亮）
            else
                love.graphics.setColor(0.6, 0.4, 0.4)  -- 敌人红色（更亮）
            end
            love.graphics.rectangle("fill", commandX, y + 5, commandWidth, rowHeight - 15, 5)
            
            -- 大营边框（金色）
            love.graphics.setColor(0.9, 0.7, 0.3)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", commandX, y + 5, commandWidth, rowHeight - 15, 5)
            love.graphics.setLineWidth(1)
            
            -- 大营名称/指挥官名称
            love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
            
            local commandName
            if player.command and player.command.name then
                commandName = player.command.name
                love.graphics.setColor(0.9, 0.9, 0.4)
            else
                commandName = "大营"
                love.graphics.setColor(1, 1, 1)
            end
            
            -- 截断长名称
            if #commandName > 5 then
                commandName = string.sub(commandName, 1, 4) .. ".."
            end
            
            love.graphics.print("★ " .. commandName, commandX + 8, y + 8)
            
            -- 显示HP标签
            love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
            love.graphics.setColor(0.6, 0.8, 0.6)
            love.graphics.print("HP: " .. player.commandHp .. "/" .. player.maxCommandHp, commandX + 10, y + 25)
        else
            -- 普通单位排（殿后、中军、先锋）
            for j, unit in ipairs(units) do
                local x = rowStartX + (j - 1) * (unitWidth + unitGap)
                
                -- 单位背景
                if playerId == 1 then
                    love.graphics.setColor(0.3, 0.5, 0.4)
                else
                    love.graphics.setColor(0.5, 0.3, 0.3)
                end
                love.graphics.rectangle("fill", x, y + 5, unitWidth, rowHeight - 15, 3)
                
                -- 单位边框
                if playerId == activePlayer and rowType == Battle.ROW.REAR and currentPhase == "deploy" then
                    love.graphics.setColor(0.9, 0.9, 0.3)  -- 可交互高亮
                else
                    love.graphics.setColor(0.6, 0.6, 0.6)
                end
                love.graphics.rectangle("line", x, y + 5, unitWidth, rowHeight - 15, 3)
                
                -- 单位名称：优先显示人物名称，其次显示位置
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(chineseFont[12] or love.graphics.newFont(12))
                
                local displayName
                if unit.card and unit.card.name then
                    -- 有卡牌时显示人物名称
                    displayName = unit.card.name
                elseif unit.name then
                    -- 备用：显示单位保存的名称
                    displayName = unit.name
                else
                    -- 默认：显示位置
                    displayName = Battle.ROW_NAME[rowType] .. j
                end
                
                -- 截断长名称以适应显示区域
                if #displayName > 6 then
                    displayName = string.sub(displayName, 1, 5) .. ".."
                end
                
                love.graphics.print(displayName, x + 5, y + 8)
                
                -- 显示位置标签（小字体，在人物名称下方）
                love.graphics.setFont(chineseFont[9] or love.graphics.newFont(9))
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.print(Battle.ROW_NAME[rowType] .. j, x + 5, y + 23)
                
                -- 战力值
                local currentPower = unit.currentPower or 0
                if currentPower > 0 then
                    love.graphics.setColor(0.9, 0.7, 0.3)
                    love.graphics.setFont(chineseFont[10] or love.graphics.newFont(10))
                    love.graphics.print("战力:" .. currentPower, x + 5, y + 36)
                end
                
                -- 存储点击区域（用于交互）
                unit.clickArea = {x = x, y = y + 5, width = unitWidth, height = rowHeight - 15}
            end
        end
    end
    
    -- 绘制大营生命值
    for i, player in ipairs(players) do
        local y = (i == 1) and startY or (startY + 7 * rowHeight)
        local x = startX + 420
        
        -- HP条背景
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", x, y + 10, 150, 20)
        
        -- HP条
        local hpPercent = player.commandHp / player.maxCommandHp
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.rectangle("fill", x, y + 10, 150 * hpPercent, 20)
        
        -- HP文字
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(chineseFont[14])
        love.graphics.print(player.commandHp .. "/" .. player.maxCommandHp, x + 50, y + 12)
    end
    
    -- 显示待分配战力
    if currentPhase == "deploy" then
        local player = players[activePlayer]
        love.graphics.setColor(0.9, 0.7, 0.3)
        love.graphics.setFont(chineseFont[18])
        love.graphics.print("待分配战力: " .. player.tempPower, 20, 100)
    end
    
    -- 绘制战力球动画
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
    
    -- 根据阶段显示不同按钮
    if currentPhase == "ready" then
        -- 开始回合按钮
        table.insert(buttons, {
            text = "开始回合",
            x = screenWidth / 2 - 60,
            y = screenHeight - 100,
            width = 120,
            height = 50,
            onClick = function() Battle.startRound() end
        })
    elseif currentPhase == "victory" then
        -- 战斗结束后的返回按钮
        table.insert(buttons, {
            text = "返回主菜单",
            x = screenWidth / 2 - 70,
            y = screenHeight - 100,
            width = 140,
            height = 50,
            onClick = function() Battle.returnToMenu() end
        })
    end
    
    -- 绘制按钮
    love.graphics.setFont(chineseFont[16])
    for _, btn in ipairs(buttons) do
        -- 检测悬停
        local mx, my = love.mouse.getPosition()
        local hovered = mx >= btn.x and mx <= btn.x + btn.width
                        and my >= btn.y and my <= btn.y + btn.height
        
        -- 按钮背景
        if hovered then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.3, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5)
        
        -- 按钮边框
        love.graphics.setColor(0.6, 0.7, 0.8)
        love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5)
        
        -- 按钮文字
        love.graphics.setColor(1, 1, 1)
        local textWidth = chineseFont[16]:getWidth(btn.text)
        love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2, btn.y + 10)
        
        -- 存储按钮点击区域
        btn.clickArea = {x = btn.x, y = btn.y, width = btn.width, height = btn.height}
    end
    
    -- 保存按钮列表供点击检测使用
    Battle.currentButtons = buttons
end

function Battle.drawLog(screenWidth, screenHeight)
    local logX = screenWidth - 300
    local logY = screenHeight - 200
    local logHeight = 180
    
    -- 日志背景
    love.graphics.setColor(0.15, 0.15, 0.2, 0.9)
    love.graphics.rectangle("fill", logX, logY, 280, logHeight)
    
    -- 日志边框
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", logX, logY, 280, logHeight)
    
    -- 日志标题
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.setFont(chineseFont[14] or love.graphics.newFont(14))
    love.graphics.print("战斗日志", logX + 10, logY + 5)
    
    -- 日志内容
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
-- 输入处理
-- ============================================================================

function Battle.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- 检查按钮点击
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
    
    -- 检查殿后单位点击（部署阶段）
    if currentPhase == "deploy" then
        local player = players[activePlayer]
        for i, unit in ipairs(player.units[Battle.ROW.REAR]) do
            if unit.clickArea then
                if x >= unit.clickArea.x and x <= unit.clickArea.x + unit.clickArea.width
                   and y >= unit.clickArea.y and y <= unit.clickArea.y + unit.clickArea.height then
                    -- 向该单位部署1点战力
                    Battle.deployPower(i, 1)
                    return
                end
            end
        end
    end
end

function Battle.exit()
    print("退出战斗...")
end

return Battle
