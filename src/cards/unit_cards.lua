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
    },
    {
        id = "zhang_fei",
        name = "Zhang Fei",
        title = "Ten Thousand Enemy",
        rarity = UnitCards.RARITY.RARE,
        description = "Fierce warrior",
        flavorText = "I am Zhang Fei!",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 38, abilities = {{type = UnitCards.ABILITY.BONUS_ATTACK, value = 3, desc = "Vanguard +3 atk"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 5, defense = 1, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 4, defense = 1, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 3, defense = 1, abilities = {} }
        }
    },
    {
        id = "zhao_yun",
        name = "Zhao Yun",
        title = "General of Victory",
        rarity = UnitCards.RARITY.RARE,
        description = "Brave and loyal",
        flavorText = "I am Zhao Yun!",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 38, abilities = {{type = UnitCards.ABILITY.AMBUSH, value = 1, desc = "Steal 1 power"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 3, defense = 3, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 2, defense = 3, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 2, abilities = {} }
        }
    },
    {
        id = "sun_quan",
        name = "Sun Quan",
        title = "Emperor Da",
        rarity = UnitCards.RARITY.RARE,
        description = "Defensive ruler",
        flavorText = "Like Sun Zhongmou",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 45, abilities = {{type = UnitCards.ABILITY.BONUS_DEFENSE, value = 2, desc = "+2 Defense"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 2, defense = 3, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 1, defense = 3, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 1, defense = 2, abilities = {} }
        }
    },
    {
        id = "zhou_yu",
        name = "Zhou Yu",
        title = "Handsome Zhou",
        rarity = UnitCards.RARITY.RARE,
        description = "Talented commander",
        flavorText = "Why Zhou Yu?",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 33, abilities = {{type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "+1 Attack"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 3, defense = 1, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 2, defense = 2, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 1, abilities = {} }
        }
    },
    {
        id = "simayi",
        name = "Sima Yi",
        title = "Tomb Tiger",
        rarity = UnitCards.RARITY.RARE,
        description = "Cunning strategist",
        flavorText = "Adapt to changes",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 34, abilities = {{type = UnitCards.ABILITY.AMBUSH, value = 2, desc = "Steal 2 power"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 2, defense = 3, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 2, defense = 3, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 1, defense = 2, abilities = {} }
        }
    },
    {
        id = "huang_zhong",
        name = "Huang Zhong",
        title = "Old But Strong",
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "Veteran archer",
        flavorText = "My blade is sharp",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 36, abilities = {{type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "+1 Attack"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 3, defense = 1, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 3, defense = 1, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 3, defense = 1, abilities = {} }
        }
    },
    {
        id = "dian_wei",
        name = "Dian Wei",
        title = "Evil Comes",
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "Bodyguard of Cao",
        flavorText = "Go my lord!",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 40, abilities = {{type = UnitCards.ABILITY.DEFEND, value = 0.2, desc = "-20% Damage"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 4, defense = 2, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 3, defense = 2, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 3, abilities = {} }
        }
    },
    {
        id = "zhang_liao",
        name = "Zhang Liao",
        title = "Fear at Xiaoyao",
        rarity = UnitCards.RARITY.RARE,
        description = "Defeated ten thousand",
        flavorText = "Who dares fight?",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 37, abilities = {{type = UnitCards.ABILITY.CHARGE, value = 1.2, desc = "DMG x1.2"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 4, defense = 1, abilities = {{type = UnitCards.ABILITY.CHARGE, value = 1.5, desc = "DMG x1.5"}} },
            [UnitCards.POSITION.CENTER] = { attack = 3, defense = 2, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 3, defense = 1, abilities = {} }
        }
    },
    {
        id = "taishi_ci",
        name = "Taishi Ci",
        title = "Loyal and Faithful",
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "Skilled archer",
        flavorText = "Make a name!",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 35, abilities = {{type = UnitCards.ABILITY.AMBUSH, value = 1, desc = "Steal 1 power"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 3, defense = 1, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 3, defense = 0, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 3, defense = 0, abilities = {} }
        }
    },
    {
        id = "lv_meng",
        name = "Lu Meng",
        title = "Scholar Warrior",
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "Learned general",
        flavorText = "Study and fight",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 36, abilities = {{type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.15, desc = "+15% transfer"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 3, defense = 2, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 2, defense = 3, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 2, abilities = {} }
        }
    },
    {
        id = "gan_ning",
        name = "Gan Ning",
        title = "Bell of Waves",
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "Pirate turned general",
        flavorText = "Ring the bells!",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 34, abilities = {{type = UnitCards.ABILITY.CHARGE, value = 1.15, desc = "DMG x1.15"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 3, defense = 1, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 3, defense = 1, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 2, abilities = {} }
        }
    },
    {
        id = "xu_chu",
        name = "Xu Chu",
        title = "Tiger Guard",
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "Cao Cao's guard",
        flavorText = "I guard the lord",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 39, abilities = {{type = UnitCards.ABILITY.DEFEND, value = 0.15, desc = "-15% Damage"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 4, defense = 1, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 3, defense = 1, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 2, abilities = {} }
        }
    },
    {
        id = "ma_chao",
        name = "Ma Chao",
        title = "Splendid Ma",
        rarity = UnitCards.RARITY.RARE,
        description = "Fierce cavalry",
        flavorText = "The Ma family!",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 36, abilities = {{type = UnitCards.ABILITY.CHARGE, value = 1.25, desc = "DMG x1.25"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 4, defense = 1, abilities = {{type = UnitCards.ABILITY.CHARGE, value = 1.6, desc = "DMG x1.6"}} },
            [UnitCards.POSITION.CENTER] = { attack = 3, defense = 2, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 2, abilities = {} }
        }
    },
    {
        id = "huang_gai",
        name = "Huang Gai",
        title = "Old General",
        rarity = UnitCards.RARITY.COMMON,
        description = "Veteran of Wu",
        flavorText = "Fake surrender!",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 38, abilities = {} },
            [UnitCards.POSITION.VANGUARD] = { attack = 3, defense = 1, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 2, defense = 2, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 1, abilities = {} }
        }
    },
    {
        id = "wei_yan",
        name = "Wei Yan",
        title = "Double Blade",
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "Fierce general",
        flavorText = "Who am I?",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 37, abilities = {{type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "+1 Attack"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 4, defense = 0, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 3, defense = 1, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 2, defense = 1, abilities = {} }
        }
    },
    {
        id = "jiang_wei",
        name = "Jiang Wei",
        title = "Young Qilin",
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "Zhuge's heir",
        flavorText = "Restore Han!",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 34, abilities = {{type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.2, desc = "+20% transfer"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 2, defense = 2, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 2, defense = 2, abilities = {{type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.25, desc = "+25% transfer"}} },
            [UnitCards.POSITION.REAR] = { attack = 1, defense = 3, abilities = {} }
        }
    },
    {
        id = "xun_yu",
        name = "Xun Yu",
        title = "King's Helper",
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "Cao Cao's advisor",
        flavorText = "Loyal and true",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = { hp = 32, abilities = {{type = UnitCards.ABILITY.BONUS_GENERATE, value = 3, desc = "+3 Power/turn"}} },
            [UnitCards.POSITION.VANGUARD] = { attack = 1, defense = 2, abilities = {} },
            [UnitCards.POSITION.CENTER] = { attack = 1, defense = 3, abilities = {} },
            [UnitCards.POSITION.REAR] = { attack = 1, defense = 2, abilities = {{type = UnitCards.ABILITY.BONUS_GENERATE, value = 4, desc = "+4 Power/turn"}} }
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
