--[[
    卡牌基类
--]]

local Card = {}
Card.__index = Card

-- 卡牌类型
Card.TYPE = {
    ATTACK = "attack",
    DEFENSE = "defense",
    SKILL = "skill",
    POWER = "power"
}

-- 卡牌稀有度
Card.RARITY = {
    COMMON = "common",
    UNCOMMON = "uncommon",
    RARE = "rare"
}

function Card.new(data)
    local self = setmetatable({}, Card)
    
    self.id = data.id or "unknown"
    self.name = data.name or "未命名卡牌"
    self.description = data.description or ""
    self.type = data.type or Card.TYPE.ATTACK
    self.rarity = data.rarity or Card.RARITY.COMMON
    self.cost = data.cost or 1
    
    -- 效果数值
    self.damage = data.damage or 0
    self.block = data.block or 0
    self.heal = data.heal or 0
    self.energyGain = data.energyGain or 0
    self.cardDraw = data.cardDraw or 0
    
    -- 特殊效果
    self.effects = data.effects or {}
    
    return self
end

function Card:clone()
    return Card.new({
        id = self.id,
        name = self.name,
        description = self.description,
        type = self.type,
        rarity = self.rarity,
        cost = self.cost,
        damage = self.damage,
        block = self.block,
        heal = self.heal,
        energyGain = self.energyGain,
        cardDraw = self.cardDraw,
        effects = self.effects
    })
end

function Card:canPlay(player)
    return player.energy >= self.cost
end

function Card:play(player, target)
    if not self:canPlay(player) then
        return false
    end
    
    -- 消耗能量
    player.energy = player.energy - self.cost
    
    -- 应用效果
    self:applyEffect(player, target)
    
    return true
end

function Card:applyEffect(player, target)
    -- 造成伤害
    if self.damage > 0 and target then
        target.hp = math.max(0, target.hp - self.damage)
    end
    
    -- 获得格挡
    if self.block > 0 then
        player.block = (player.block or 0) + self.block
    end
    
    -- 治疗
    if self.heal > 0 then
        player.hp = math.min(player.maxHp, player.hp + self.heal)
    end
    
    -- 获得能量
    if self.energyGain > 0 then
        player.energy = player.energy + self.energyGain
    end
    
    -- 抽牌
    if self.cardDraw > 0 then
        -- 抽牌逻辑由战斗系统处理
    end
    
    -- 应用特殊效果
    for _, effect in ipairs(self.effects) do
        effect:apply(player, target)
    end
end

function Card:getDescription()
    return self.description
end

return Card
