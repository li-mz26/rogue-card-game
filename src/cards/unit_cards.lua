-- Unit Cards: Historical Characters
local UnitCards = {}

UnitCards.RARITY = {
    COMMON = "common",
    UNCOMMON = "uncommon", 
    RARE = "rare",
    LEGENDARY = "legendary"
}

UnitCards.POSITION = {
    COMMAND = "command",
    VANGUARD = "vanguard",
    CENTER = "center",
    REAR = "rear"
}

UnitCards.ABILITY = {
    BONUS_ATTACK = "bonus_attack",
    BONUS_DEFENSE = "bonus_defense",
    BONUS_TRANSFER = "bonus_transfer",
    BONUS_GENERATE = "bonus_generate",
    CHARGE = "charge",
    DEFEND = "defend",
    AMBUSH = "ambush",
    INSPIRE = "inspire",
}

UnitCards.DATABASE = {
    {
        id = "liu_bei",
        name = "Liu Bei",
        title = "Emperor Zhaolie",
        rarity = UnitCards.RARITY.RARE,
        description = "Benevolent leader",
        flavorText = "Do not evil though small",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 40, abilities = {{type = UnitCards.ABILITY.BONUS_GENERATE, value = 2, desc = "+2 Power/turn"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 2, defense = 2, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 1, defense = 2, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 1, defense = 1, abilities = {} }
        }
    },
    {
        id = "cao_cao",
        name = "Cao Cao",
        title = "Emperor Wu",
        rarity = UnitCards.RARITY.RARE,
        description = "Strategic genius",
        flavorText = "Better I betray",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 35, abilities = {{type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.2, desc = "+20% transfer"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 3, defense = 2, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 2, defense = 2, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 1, abilities = {} }
        }
    },
    {
        id = "guan_yu",
        name = "Guan Yu",
        title = "Saint of War",
        rarity = UnitCards.RARITY.LEGENDARY,
        description = "Mighty warrior",
        flavorText = "Jade can be crushed",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 35, abilities = {{type = UnitCards.ABILITY.BONUS_ATTACK, value = 2, desc = "Vanguard +2 atk"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 4, defense = 2, abilities = {{type = UnitCards.ABILITY.CHARGE, value = 2, desc = "DMG x2"}} },
            [UnitCards.POSITION.CENTER] = { attack = 3, defense = 2, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 2, abilities = {} }
        }
    },
    {
        id = "zhuge_liang",
        name = "Zhuge Liang",
        title = "Sleeping Dragon",
        rarity = UnitCards.RARITY.LEGENDARY,
        description = "Master strategist",
        flavorText = "Devoted to the end",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 32, abilities = {{type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.3, desc = "+30% transfer"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 2, defense = 2, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 2, defense = 2, abilities = {{type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.4, desc = "+40% transfer"}} },
            [UnitCards.POSITION.REAR] = { attack = 1, defense = 2, abilities = {{type = UnitCards.ABILITY.BONUS_GENERATE, value = 3, desc = "+3 Power/turn"}} }
        }
    }
}

function UnitCards.getAll()
    return UnitCards.DATABASE
end

function UnitCards.getById(id)
    for _, card in ipairs(UnitCards.DATABASE) do
        if card.id == id then return card end
    end
    return nil
end

function UnitCards.getByRarity(rarity)
    local result = {}
    for _, card in ipairs(UnitCards.DATABASE) do
        if card.rarity == rarity then table.insert(result, card) end
    end
    return result
end

function UnitCards.getEffectAtPosition(cardId, position)
    local card = UnitCards.getById(cardId)
    if not card or not card.positionEffects then return nil end
    return card.positionEffects[position]
end

function UnitCards.createInstance(cardId, position)
    local template = UnitCards.getById(cardId)
    if not template then return nil end
    local effect = position and UnitCards.getEffectAtPosition(cardId, position) or nil
    local instance = {
        id = template.id,
        name = template.name,
        title = template.title,
        rarity = template.rarity,
        description = template.description,
        flavorText = template.flavorText,
        instanceId = tostring(math.random(1000000)),
        position = position
    }
    if effect then
        instance.hp = effect.hp or 10
        instance.maxHp = effect.hp or 10
        instance.currentHp = effect.hp or 10
        instance.attack = effect.attack or 0
        instance.defense = effect.defense or 0
        instance.abilities = effect.abilities or {}
    else
        instance.hp = 10
        instance.maxHp = 10
        instance.currentHp = 10
        instance.attack = 0
        instance.defense = 0
        instance.abilities = {}
    end
    return instance
end

function UnitCards.getPositionName(position)
    local names = { command = "Command", vanguard = "Vanguard", center = "Center", rear = "Rear" }
    return names[position] or "Unknown"
end

function UnitCards.getRarityColor(rarity)
    local colors = {
        common = {0.7, 0.7, 0.7},
        uncommon = {0.2, 0.8, 0.2},
        rare = {0.2, 0.5, 1},
        legendary = {1, 0.8, 0.2}
    }
    return colors[rarity] or colors.common
end

return UnitCards
