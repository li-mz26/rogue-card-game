--[[
    玩家类
--]]

local Card = require('src.cards.card')

local Player = {}
Player.__index = Player

function Player.new()
    local self = setmetatable({}, Player)
    
    -- 基础属性
    self.hp = 80
    self.maxHp = 80
    self.block = 0
    
    -- 能量系统
    self.energy = 3
    self.maxEnergy = 3
    
    -- 卡牌系统
    self.deck = {}
    self.hand = {}
    self.discard = {}
    self.exhaust = {}
    
    -- 状态效果
    self.statusEffects = {}
    
    -- 遗物
    self.relics = {}
    
    -- 金币
    self.gold = 99
    
    return self
end

function Player:initStarterDeck()
    -- 添加基础攻击牌
    for i = 1, 5 do
        table.insert(self.deck, Card.new({
            id = "strike_" .. i,
            name = "打击",
            type = Card.TYPE.ATTACK,
            cost = 1,
            damage = 6,
            description = "造成 6 点伤害"
        }))
    end
    
    -- 添加基础防御牌
    for i = 1, 5 do
        table.insert(self.deck, Card.new({
            id = "defend_" .. i,
            name = "防御",
            type = Card.TYPE.DEFENSE,
            cost = 1,
            block = 5,
            description = "获得 5 点格挡"
        }))
    end
end

function Player:takeDamage(amount)
    -- 先消耗格挡
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

function Player:heal(amount)
    self.hp = math.min(self.maxHp, self.hp + amount)
end

function Player:addBlock(amount)
    self.block = self.block + amount
end

function Player:startTurn()
    -- 恢复能量
    self.energy = self.maxEnergy
    
    -- 清除格挡（某些 Roguelike 规则保留）
    -- self.block = 0
    
    -- 抽牌
    self:drawCards(5)
    
    -- 触发回合开始效果
    self:triggerStatusEffects("turnStart")
end

function Player:endTurn()
    -- 丢弃手牌
    for _, card in ipairs(self.hand) do
        table.insert(self.discard, card)
    end
    self.hand = {}
    
    -- 触发回合结束效果
    self:triggerStatusEffects("turnEnd")
end

function Player:drawCards(count)
    for i = 1, count do
        if #self.deck == 0 then
            -- 牌组空了，洗 discard
            if #self.discard == 0 then
                break -- 没有牌可抽
            end
            self.deck = self.discard
            self.discard = {}
            self:shuffleDeck()
        end
        
        if #self.deck > 0 then
            local card = table.remove(self.deck)
            table.insert(self.hand, card)
        end
    end
end

function Player:shuffleDeck()
    for i = #self.deck, 2, -1 do
        local j = math.random(i)
        self.deck[i], self.deck[j] = self.deck[j], self.deck[i]
    end
end

function Player:addCardToDeck(card)
    table.insert(self.deck, card)
end

function Player:removeCardFromDeck(card)
    for i, c in ipairs(self.deck) do
        if c == card then
            table.remove(self.deck, i)
            return true
        end
    end
    return false
end

function Player:addStatusEffect(effect)
    table.insert(self.statusEffects, effect)
end

function Player:triggerStatusEffects(trigger)
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

function Player:addRelic(relic)
    table.insert(self.relics, relic)
    if relic.onObtain then
        relic:onObtain(self)
    end
end

function Player:isAlive()
    return self.hp > 0
end

return Player
