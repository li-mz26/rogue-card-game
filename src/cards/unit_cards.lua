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
        name = "刘备",
        title = "昭烈帝",
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
        name = "曹操",
        title = "武帝",
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
        name = "关羽",
        title = "武圣",
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
        name = "诸葛亮",
        title = "卧龙",
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
        name = "张飞",
        title = "万人敌",
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
        name = "赵云",
        title = "常胜将军",
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
        name = "孙权",
        title = "大帝",
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
        name = "周瑜",
        title = "美周郎",
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
        name = "司马懿",
        title = "冢虎",
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
        name = "黄忠",
        title = "老当益壮",
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
        name = "典韦",
        title = "恶来",
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
        name = "张辽",
        title = "威震逍遥津",
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
        name = "太史慈",
        title = "义信",
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
        name = "吕蒙",
        title = "士别三日",
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
        name = "甘宁",
        title = "锦帆贼",
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
        name = "许褚",
        title = "虎痴",
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
        name = "马超",
        title = "锦马超",
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
        name = "黄盖",
        title = "老将",
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
        name = "魏延",
        title = "双刃剑",
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
        name = "姜维",
        title = "幼麟",
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
        name = "荀彧",
        title = "王佐之才",
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

UnitCards.TAGS = {
    liu_bei = { dynasty = "Three Kingdoms", surname = "Liu", origin = "Zhuo County" },
    cao_cao = { dynasty = "Three Kingdoms", surname = "Cao", origin = "Bozhou" },
    guan_yu = { dynasty = "Three Kingdoms", surname = "Guan", origin = "Xie County" },
    zhuge_liang = { dynasty = "Three Kingdoms", surname = "Zhuge", origin = "Langya" },
    zhang_fei = { dynasty = "Three Kingdoms", surname = "Zhang", origin = "Zhuo County" },
    zhao_yun = { dynasty = "Three Kingdoms", surname = "Zhao", origin = "Changshan" },
    sun_quan = { dynasty = "Three Kingdoms", surname = "Sun", origin = "Fuchun" },
    zhou_yu = { dynasty = "Three Kingdoms", surname = "Zhou", origin = "Lujiang" },
    simayi = { dynasty = "Three Kingdoms", surname = "Sima", origin = "Wen County" },
    huang_zhong = { dynasty = "Three Kingdoms", surname = "Huang", origin = "Nanyang" },
    dian_wei = { dynasty = "Three Kingdoms", surname = "Dian", origin = "Chenliu" },
    zhang_liao = { dynasty = "Three Kingdoms", surname = "Zhang", origin = "Mayi" },
    taishi_ci = { dynasty = "Three Kingdoms", surname = "Taishi", origin = "Donglai" },
    lv_meng = { dynasty = "Three Kingdoms", surname = "Lv", origin = "Runan" },
    gan_ning = { dynasty = "Three Kingdoms", surname = "Gan", origin = "Baxi" },
    xu_chu = { dynasty = "Three Kingdoms", surname = "Xu", origin = "Qiao" },
    ma_chao = { dynasty = "Three Kingdoms", surname = "Ma", origin = "Maoling" },
    huang_gai = { dynasty = "Three Kingdoms", surname = "Huang", origin = "Lingling" },
    wei_yan = { dynasty = "Three Kingdoms", surname = "Wei", origin = "Yiyang" },
    jiang_wei = { dynasty = "Three Kingdoms", surname = "Jiang", origin = "Tianshui" },
    xun_yu = { dynasty = "Three Kingdoms", surname = "Xun", origin = "Yingchuan" }
}

local function clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function buildTransferStats(effect)
    local attack = (effect and effect.attack) or 0
    local defense = (effect and effect.defense) or 0
    local sendPower = 0.52 + attack * 0.07
    local recvPower = 0.5 + defense * 0.08
    local interceptPower = 0.08 + defense * 0.06
    local powerMod = 0

    for _, ability in ipairs((effect and effect.abilities) or {}) do
        if ability.type == UnitCards.ABILITY.BONUS_TRANSFER then
            powerMod = powerMod + (ability.value or 0)
        elseif ability.type == UnitCards.ABILITY.CHARGE then
            sendPower = sendPower + (ability.value or 0) * 0.05
        elseif ability.type == UnitCards.ABILITY.DEFEND then
            interceptPower = interceptPower + (ability.value or 0) * 0.5
        elseif ability.type == UnitCards.ABILITY.AMBUSH then
            interceptPower = interceptPower + (ability.value or 0) * 0.07
        end
    end

    return {
        sendPower = clamp(sendPower, 0.1, 1.2),
        recvPower = clamp(recvPower, 0.1, 1.2),
        interceptPower = clamp(interceptPower, 0, 0.9),
        powerMod = clamp(powerMod, -0.4, 1.2)
    }
end

function UnitCards.getAll()
    return UnitCards.DATABASE
end

-- Six-dimensional stats for FIFA/NBA2K style card display
-- 武力(Martial), 智谋(Strategy), 统率(Command), 防御(Defense), 速度(Speed), 体力(Vitality)
UnitCards.STAT_NAMES = { "Martial", "Strategy", "Command", "Defense", "Speed", "Vitality" }
UnitCards.STAT_LABELS = { "武力", "智谋", "统率", "防御", "速度", "体力" }

local function calcSixDimensionalStats(cardData)
    local cmd = cardData.positionEffects and cardData.positionEffects.command or {}
    local vg = cardData.positionEffects and cardData.positionEffects.vanguard or {}
    local ct = cardData.positionEffects and cardData.positionEffects.center or {}
    local rr = cardData.positionEffects and cardData.positionEffects.rear or {}

    local hp = cmd.hp or 30
    local vgAtk = vg.attack or 0
    local vgDef = vg.defense or 0
    local ctAtk = ct.attack or 0
    local ctDef = ct.defense or 0
    local rrAtk = rr.attack or 0
    local rrDef = rr.defense or 0

    local abilities = cmd.abilities or {}

    local martial = 50 + vgAtk * 12 + rrAtk * 3
    local strategy = 50 + ctAtk * 10 + rrAtk * 2
    local command = 50 + ctDef * 10 + (hp - 30) * 0.8
    local defense = 50 + vgDef * 12 + ctDef * 8 + rrDef * 4
    local speed = 50 + vgAtk * 6 + vgDef * 3
    local vitality = 40 + hp * 1.2

    for _, ab in ipairs(abilities) do
        if ab.type == "bonus_attack" then
            martial = martial + (ab.value or 0) * 8
        elseif ab.type == "bonus_defense" then
            defense = defense + (ab.value or 0) * 10
        elseif ab.type == "bonus_transfer" then
            command = command + (ab.value or 0) * 25
        elseif ab.type == "bonus_generate" then
            strategy = strategy + (ab.value or 0) * 6
        elseif ab.type == "charge" then
            martial = martial + (ab.value or 0) * 5
            speed = speed + (ab.value or 0) * 4
        elseif ab.type == "ambush" then
            strategy = strategy + (ab.value or 0) * 8
            speed = speed + (ab.value or 0) * 5
        elseif ab.type == "defend" then
            defense = defense + (ab.value or 0) * 20
        end
    end

    local rarityBoost = {
        common = 0,
        uncommon = 5,
        rare = 10,
        legendary = 18
    }
    local boost = rarityBoost[cardData.rarity] or 0
    martial = math.min(99, math.floor(martial + boost))
    strategy = math.min(99, math.floor(strategy + boost))
    command = math.min(99, math.floor(command + boost))
    defense = math.min(99, math.floor(defense + boost))
    speed = math.min(99, math.floor(speed + boost))
    vitality = math.min(99, math.floor(vitality + boost))

    return {
        martial = martial,
        strategy = strategy,
        command = command,
        defense = defense,
        speed = speed,
        vitality = vitality
    }
end

function UnitCards.calcOverallRating(sixStats)
    if not sixStats then return 50 end
    local weights = { 1.15, 0.95, 1.0, 0.9, 0.85, 0.75 }
    local total = 0
    local statList = { sixStats.martial, sixStats.strategy, sixStats.command, sixStats.defense, sixStats.speed, sixStats.vitality }
    for i, v in ipairs(statList) do
        total = total + v * weights[i]
    end
    return math.floor(total / 5.6)
end

function UnitCards.getCardStats(cardData)
    return calcSixDimensionalStats(cardData)
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
    local tagMeta = UnitCards.TAGS[cardId] or {}
    local transfer = buildTransferStats(effect)
    local instance = {
        id = template.id,
        name = template.name,
        title = template.title,
        rarity = template.rarity,
        description = template.description,
        flavorText = template.flavorText,
        instanceId = tostring(math.random(1000000)),
        position = position,
        tags = {
            dynasty = tagMeta.dynasty,
            surname = tagMeta.surname,
            origin = tagMeta.origin
        },
        sendPower = transfer.sendPower,
        recvPower = transfer.recvPower,
        interceptPower = transfer.interceptPower,
        powerMod = transfer.powerMod
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
