--[[
    卡牌战争 - 战斗系统
    核心机制：4排11单位阵型，战力层层传递攻击大营
--]]

local Battle = {}

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
-- 回合流程
-- ============================================================================

function Battle.startTurn()
    local player = players[activePlayer]
    
    -- 阶段 1: 生成战力
    currentPhase = "generate"
    local generatedPower = player.basePowerGeneration
    player.tempPower = generatedPower
    addLog(player.name .. " 大营生成 " .. generatedPower .. " 点战力")
    
    -- 自动进入部署阶段
    currentPhase = "deploy"
    addLog("请将战力部署到殿后单位")
end

-- 部署战力到殿后单位
function Battle.deployPower(rearUnitIndex, amount)
    local player = players[activePlayer]
    
    if currentPhase ~= "deploy" then
        addLog("错误：当前不是部署阶段")
        return false
    end
    
    if amount > player.tempPower then
        addLog("错误：战力不足")
        return false
    end
    
    if rearUnitIndex < 1 or rearUnitIndex > 3 then
        addLog("错误：无效的殿后单位")
        return false
    end
    
    local rearUnit = player.units[Battle.ROW.REAR][rearUnitIndex]
    if rearUnit.currentPower + amount > rearUnit.maxPower then
        addLog("错误：超出单位战力上限")
        return false
    end
    
    -- 部署战力
    rearUnit.currentPower = rearUnit.currentPower + amount
    player.tempPower = player.tempPower - amount
    
    addLog(player.name .. " 向 殿后" .. rearUnitIndex .. " 部署 " .. amount .. " 点战力")
    
    -- 如果战力分配完毕，自动开始传递
    if player.tempPower <= 0 then
        Battle.startTransfer()
    end
    
    return true
end

-- 快速平均分配战力
function Battle.autoDeploy()
    local player = players[activePlayer]
    local rearUnits = player.units[Battle.ROW.REAR]
    
    -- 平均分配到3个殿后单位
    local perUnit = math.floor(player.tempPower / 3)
    local remainder = player.tempPower % 3
    
    for i = 1, 3 do
        local amount = perUnit + (i <= remainder and 1 or 0)
        if amount > 0 then
            Battle.deployPower(i, amount)
        end
    end
end

-- 开始传递阶段
function Battle.startTransfer()
    currentPhase = "transfer"
    addLog("开始战力传递...")
    
    -- 传递顺序：殿后 → 中军 → 先锋
    local player = players[activePlayer]
    
    -- 1. 殿后 → 中军
    local rearToCenter = 0
    for i = 1, 3 do
        local rearUnit = player.units[Battle.ROW.REAR][i]
        local transferAmount = rearUnit.currentPower
        rearUnit.currentPower = 0
        rearToCenter = rearToCenter + transferAmount
    end
    
    -- 中军接收（平均分配）
    if rearToCenter > 0 then
        local perUnit = math.floor(rearToCenter / 3)
        local remainder = rearToCenter % 3
        for i = 1, 3 do
            local amount = perUnit + (i <= remainder and 1 or 0)
            player.units[Battle.ROW.CENTER][i].currentPower = amount
        end
        addLog("殿后向中军传递 " .. rearToCenter .. " 点战力")
    end
    
    -- 2. 中军 → 先锋
    local centerToVanguard = 0
    for i = 1, 3 do
        local centerUnit = player.units[Battle.ROW.CENTER][i]
        local transferAmount = centerUnit.currentPower
        centerUnit.currentPower = 0
        centerToVanguard = centerToVanguard + transferAmount
    end
    
    -- 先锋接收
    if centerToVanguard > 0 then
        local perUnit = math.floor(centerToVanguard / 3)
        local remainder = centerToVanguard % 3
        for i = 1, 3 do
            local amount = perUnit + (i <= remainder and 1 or 0)
            player.units[Battle.ROW.VANGUARD][i].currentPower = amount
        end
        addLog("中军向先锋传递 " .. centerToVanguard .. " 点战力")
    end
    
    -- 开始攻击阶段
    Battle.startAttack()
end

-- 开始攻击阶段
function Battle.startAttack()
    currentPhase = "attack"
    
    local attacker = players[activePlayer]
    local defender = players[activePlayer == 1 and 2 or 1]
    
    -- 计算总攻击力
    local totalAttack = 0
    for i = 1, 3 do
        local vanguard = attacker.units[Battle.ROW.VANGUARD][i]
        totalAttack = totalAttack + vanguard.currentPower * vanguard.attack
        vanguard.currentPower = 0  -- 消耗战力
    end
    
    if totalAttack > 0 then
        defender.commandHp = defender.commandHp - totalAttack
        addLog(attacker.name .. " 的先锋攻击敌方大营，造成 " .. totalAttack .. " 点伤害！")
        addLog(defender.name .. " 大营剩余生命值: " .. defender.commandHp)
        
        -- 检查胜利条件
        if defender.commandHp <= 0 then
            addLog(defender.name .. " 大营被攻破！")
            addLog(attacker.name .. " 获得胜利！")
            currentPhase = "victory"
            return
        end
    else
        addLog(attacker.name .. " 本回合没有造成有效伤害")
    end
    
    -- 回合结束，切换玩家
    Battle.endTurn()
end

-- 结束回合
function Battle.endTurn()
    -- 切换玩家
    activePlayer = (activePlayer == 1) and 2 or 1
    
    -- 如果两个玩家都行动过，进入下一回合
    if activePlayer == 1 then
        currentTurn = currentTurn + 1
    end
    
    addLog("---")
    addLog("第 " .. currentTurn .. " 回合 - " .. players[activePlayer].name .. " 的进攻回合")
    
    -- 开始新回合
    Battle.startTurn()
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

function Battle.update(dt)
    -- 可以在这里添加动画效果
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
            
            -- 单位名称
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(chineseFont[12])
            local name = (rowType == Battle.ROW.COMMAND) and "大营" or (Battle.ROW_NAME[rowType] .. j)
            love.graphics.print(name, x + 5, y + 8)
            
            -- 战力值
            local currentPower = unit.currentPower or 0
            if currentPower > 0 then
                love.graphics.setColor(0.9, 0.7, 0.3)
                love.graphics.print("战力:" .. currentPower, x + 5, y + 25)
            end
            
            -- 存储点击区域（用于交互）
            unit.clickArea = {x = x, y = y + 5, width = unitWidth, height = rowHeight - 15}
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
end

function Battle.drawButtons(screenWidth, screenHeight)
    local buttons = {}
    
    -- 根据阶段显示不同按钮
    if currentPhase == "deploy" then
        -- 自动分配按钮
        table.insert(buttons, {
            text = "自动分配",
            x = 20,
            y = screenHeight - 150,
            width = 100,
            height = 40,
            onClick = function() Battle.autoDeploy() end
        })
        
        -- 确认按钮
        table.insert(buttons, {
            text = "确认部署",
            x = 130,
            y = screenHeight - 150,
            width = 100,
            height = 40,
            onClick = function() 
                if players[activePlayer].tempPower <= 0 then
                    Battle.startTransfer()
                else
                    addLog("还有未分配的战力！")
                end
            end
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
