--[[
    敌人基类
--]]

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(data)
    local self = setmetatable({}, Enemy)
    
    self.id = data.id or "unknown"
    self.name = data.name or "敌人"
    self.hp = data.hp or 50
    self.maxHp = data.hp or 50
    self.block = 0
    
    -- 意图
    self.currentIntent = nil
    self.nextIntent = nil
    
    -- 状态效�?
    self.statusEffects = {}
    
    -- AI 行为模式
    self.behavior = data.behavior or {}
    self.turnCount = 0
    
    return self
end

function Enemy:setIntent(intent)
    self.currentIntent = intent
end

function Enemy:decideIntent()
    -- 子类重写此方法实现不同的 AI
    self.turnCount = self.turnCount + 1
    return {
        type = "attack",
        value = 10
    }
end

function Enemy:executeIntent(player)
    if not self.currentIntent then
        return
    end
    
    local intent = self.currentIntent
    
    if intent.type == "attack" then
        -- 攻击玩家
        local damage = intent.value
        player:takeDamage(damage)
        print(self.name .. " 对玩家造成 " .. damage .. " 点伤�?")
        
    elseif intent.type == "defend" then
        -- 获得格挡
        self.block = self.block + intent.value
        print(self.name .. " 获得 " .. intent.value .. " 点格�?)
        
    elseif intent.type == "buff" then
        -- 增益效果
        print(self.name .. " 使用增益技�?)
        
    elseif intent.type == "debuff" then
        -- 减益效果
        print(self.name .. " 对玩家施加减�?)
    end
    
    -- 准备下一个意�?
    self.currentIntent = self:decideIntent()
end

function Enemy:takeDamage(amount)
    -- 先消耗格�?
    if self.block > 0 then
        local blocked = math.min(self.block, amount)
        self.block = self.block - blocked
        amount = amount - blocked
    end
    
    -- 剩余伤害扣血
    if amount > 0 then
        self.hp = math.max(0, self.hp - amount)
    end
    
    return amount > 0
end

function Enemy:addBlock(amount)
    self.block = self.block + amount
end

function Enemy:addStatusEffect(effect)
    table.insert(self.statusEffects, effect)
end

function Enemy:triggerStatusEffects(trigger)
    for i = #self.statusEffects, 1, -1 do
        local effect = self.statusEffects[i]
        if effect.trigger == trigger then
            effect:apply(self)
            effect.duration = effect.duration - 1
            if effect.duration <= 0 then
                table.remove(self.statusEffects, i)
            end
        end
    end
end

function Enemy:isAlive()
    return self.hp > 0
end

function Enemy:draw(x, y)
    -- 基础绘制，子类可以覆�?
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.rectangle("fill", x, y, 100, 100)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.name, x, y - 20)
    love.graphics.print(self.hp .. "/" .. self.maxHp, x, y + 105)
end

return Enemy
