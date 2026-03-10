--[[
    历史人物单位卡牌系统
    每个卡牌代表一个可部署到阵型中的历史人物
--]]

local UnitCards = {}

-- 卡牌稀有度
UnitCards.RARITY = {
    COMMON = "common",      -- 普通
    UNCOMMON = "uncommon",  -- 稀有
    RARE = "rare",          -- 史诗
    LEGENDARY = "legendary" -- 传说
}

-- 卡牌类型（可部署位置）
UnitCards.TYPE = {
    COMMAND = "command",    -- 大营（主帅/君主）
    VANGUARD = "vanguard",  -- 先锋（猛将/骑兵）
    CENTER = "center",      -- 中军（谋士/步兵）
    REAR = "rear"           -- 殿后（弓兵/辅助）
}

-- 特殊能力类型
UnitCards.ABILITY = {
    -- 被动能力
    BONUS_ATTACK = "bonus_attack",      -- 攻击加成
    BONUS_DEFENSE = "bonus_defense",    -- 防御加成
    BONUS_TRANSFER = "bonus_transfer",  -- 传递效率加成
    BONUS_GENERATE = "bonus_generate",  -- 战力生成加成
    
    -- 主动技能
    CHARGE = "charge",                  -- 冲锋：本回合攻击翻倍
    DEFEND = "defend",                  -- 坚守：本回合减少受到伤害
    AMBUSH = "ambush",                  -- 伏击：偷取敌方战力
    INSPIRE = "inspire",                -- 鼓舞：相邻单位获得加成
}

-- ============================================================================
-- 卡牌数据库
-- ============================================================================

UnitCards.DATABASE = {
    -- ==================== 大营（主帅/君主）====================
    {
        id = "liu_bei",
        name = "刘备",
        title = "昭烈皇帝",
        type = UnitCards.TYPE.COMMAND,
        rarity = UnitCards.RARITY.RARE,
        description = "仁德之君，能鼓舞全军士气",
        hp = 40,
        abilities = {
            { type = UnitCards.ABILITY.BONUS_GENERATE, value = 2, desc = "每回合额外生成2点战力" },
            { type = UnitCards.ABILITY.INSPIRE, value = 1, desc = "所有单位攻击力+1" }
        },
        flavorText = "勿以恶小而为之，勿以善小而不为"
    },
    {
        id = "cao_cao",
        name = "曹操",
        title = "魏武帝",
        type = UnitCards.TYPE.COMMAND,
        rarity = UnitCards.RARITY.RARE,
        description = "乱世奸雄，善于用兵",
        hp = 35,
        abilities = {
            { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.2, desc = "战力传递效率+20%" },
            { type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "先锋攻击力+1" }
        },
        flavorText = "宁教我负天下人，休教天下人负我"
    },
    {
        id = "sun_quan",
        name = "孙权",
        title = "吴大帝",
        type = UnitCards.TYPE.COMMAND,
        rarity = UnitCards.RARITY.RARE,
        description = "坐断东南，善于守成",
        hp = 45,
        abilities = {
            { type = UnitCards.ABILITY.BONUS_DEFENSE, value = 2, desc = "大营防御+2" },
            { type = UnitCards.ABILITY.DEFEND, value = 0.3, desc = "受到伤害减少30%" }
        },
        flavorText = "生子当如孙仲谋"
    },
    
    -- ==================== 先锋（猛将/骑兵）====================
    {
        id = "guan_yu",
        name = "关羽",
        title = "武圣",
        type = UnitCards.TYPE.VANGUARD,
        rarity = UnitCards.RARITY.LEGENDARY,
        description = "万人敌，威震华夏",
        attack = 3,
        defense = 2,
        abilities = {
            { type = UnitCards.ABILITY.CHARGE, value = 2, desc = "冲锋：战力转化伤害×2" }
        },
        flavorText = "玉可碎而不可改其白，竹可焚而不可毁其节"
    },
    {
        id = "zhang_fei",
        name = "张飞",
        title = "万人敌",
        type = UnitCards.TYPE.VANGUARD,
        rarity = UnitCards.RARITY.RARE,
        description = "勇猛过人，声若巨雷",
        attack = 4,
        defense = 1,
        abilities = {
            { type = UnitCards.ABILITY.BONUS_ATTACK, value = 2, desc = "基础攻击力+2" }
        },
        flavorText = "燕人张飞在此！谁敢与我决一死战？"
    },
    {
        id = "zhao_yun",
        name = "赵云",
        title = "常胜将军",
        type = UnitCards.TYPE.VANGUARD,
        rarity = UnitCards.RARITY.RARE,
        description = "一身是胆，单骑救主",
        attack = 2,
        defense = 3,
        abilities = {
            { type = UnitCards.ABILITY.AMBUSH, value = 1, desc = "从敌方殿后偷取1点战力" }
        },
        flavorText = "吾乃常山赵子龙也！"
    },
    {
        id = "dian_wei",
        name = "典韦",
        title = "古之恶来",
        type = UnitCards.TYPE.VANGUARD,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "曹操帐下猛将，力大无穷",
        attack = 3,
        defense = 1,
        abilities = {},
        flavorText = "主公快走！我来断后！"
    },
    
    -- ==================== 中军（谋士/步兵）====================
    {
        id = "zhuge_liang",
        name = "诸葛亮",
        title = "卧龙",
        type = UnitCards.TYPE.CENTER,
        rarity = UnitCards.RARITY.LEGENDARY,
        description = "运筹帷幄，决胜千里",
        attack = 1,
        defense = 1,
        abilities = {
            { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.3, desc = "传递效率+30%" },
            { type = UnitCards.ABILITY.BONUS_GENERATE, value = 1, desc = "每回合额外生成1点战力" }
        },
        flavorText = "鞠躬尽瘁，死而后已"
    },
    {
        id = "zhou_yu",
        name = "周瑜",
        title = "美周郎",
        type = UnitCards.TYPE.CENTER,
        rarity = UnitCards.RARITY.RARE,
        description = "曲有误，周郎顾",
        attack = 2,
        defense = 1,
        abilities = {
            { type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "相邻先锋攻击力+1" }
        },
        flavorText = "既生瑜，何生亮"
    },
    {
        id = "simayi",
        name = "司马懿",
        title = "冢虎",
        type = UnitCards.TYPE.CENTER,
        rarity = UnitCards.RARITY.RARE,
        description = "老谋深算，隐忍不发",
        attack = 1,
        defense = 2,
        abilities = {
            { type = UnitCards.ABILITY.AMBUSH, value = 2, desc = "每回合偷取敌方2点战力" }
        },
        flavorText = "夫处世之道，亦即应变之术"
    },
    {
        id = "xun_yu",
        name = "荀彧",
        title = "王佐之才",
        type = UnitCards.TYPE.CENTER,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "曹操的'张良'",
        attack = 0,
        defense = 2,
        abilities = {
            { type = UnitCards.ABILITY.BONUS_GENERATE, value = 2, desc = "战力生成+2" }
        },
        flavorText = "秉忠贞之志，守谦退之节"
    },
    
    -- ==================== 殿后（弓兵/辅助）====================
    {
        id = "huang_zhong",
        name = "黄忠",
        title = "老当益壮",
        type = UnitCards.TYPE.REAR,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "百步穿杨，老当益壮",
        attack = 2,
        defense = 1,
        abilities = {
            { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.15, desc = "该单位传递效率+15%" }
        },
        flavorText = "竖子欺我年老！吾手中宝刀却不老！"
    },
    {
        id = "tai_shi_ci",
        name = "太史慈",
        title = "信义笃烈",
        type = UnitCards.TYPE.REAR,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "猿臂善射，弦不虚发",
        attack = 2,
        defense = 0,
        abilities = {
            { type = UnitCards.ABILITY.AMBUSH, value = 1, desc = "从敌方先锋偷取1点战力" }
        },
        flavorText = "大丈夫生于乱世，当带三尺剑立不世之功"
    },
    {
        id = "zhang_liao",
        name = "张辽",
        title = "威震逍遥津",
        type = UnitCards.TYPE.REAR,
        rarity = UnitCards.RARITY.RARE,
        description = "以八百破十万",
        attack = 3,
        defense = 1,
        abilities = {
            { type = UnitCards.ABILITY.CHARGE, value = 1.5, desc = "传递到中军时战力×1.5" }
        },
        flavorText = "张辽在此，谁敢一战？"
    },
    {
        id = "jiang_wei",
        name = "姜维",
        title = "幼麟",
        type = UnitCards.TYPE.REAR,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "继承武侯遗志",
        attack = 1,
        defense = 2,
        abilities = {
            { type = UnitCards.ABILITY.DEFEND, value = 0.2, desc = "减少20%战力损失" }
        },
        flavorText = "臣有一计，可使汉室幽而复明"
    }
}

-- ============================================================================
-- 辅助函数
-- ============================================================================

-- 根据ID获取卡牌
function UnitCards.getById(id)
    for _, card in ipairs(UnitCards.DATABASE) do
        if card.id == id then
            return card
        end
    end
    return nil
end

-- 获取指定类型的所有卡牌
function UnitCards.getByType(cardType)
    local result = {}
    for _, card in ipairs(UnitCards.DATABASE) do
        if card.type == cardType then
            table.insert(result, card)
        end
    end
    return result
end

-- 获取指定稀有度的所有卡牌
function UnitCards.getByRarity(rarity)
    local result = {}
    for _, card in ipairs(UnitCards.DATABASE) do
        if card.rarity == rarity then
            table.insert(result, card)
        end
    end
    return result
end

-- 创建卡牌实例（用于游戏）
function UnitCards.createInstance(cardId)
    local template = UnitCards.getById(cardId)
    if not template then
        return nil
    end
    
    -- 复制卡牌数据
    local instance = {}
    for k, v in pairs(template) do
        if type(v) == "table" then
            instance[k] = {}
            for kk, vv in pairs(v) do
                instance[k][kk] = vv
            end
        else
            instance[k] = v
        end
    end
    
    -- 实例特有属性
    instance.instanceId = tostring(math.random(1000000))
    instance.currentHp = template.hp or 10
    instance.maxHp = template.hp or 10
    
    return instance
end

-- 获取卡牌类型中文名
function UnitCards.getTypeName(cardType)
    local names = {
        command = "大营",
        vanguard = "先锋",
        center = "中军",
        rear = "殿后"
    }
    return names[cardType] or "未知"
end

-- 获取稀有度颜色
function UnitCards.getRarityColor(rarity)
    local colors = {
        common = {0.7, 0.7, 0.7},      -- 灰色
        uncommon = {0.2, 0.8, 0.2},    -- 绿色
        rare = {0.2, 0.5, 1},          -- 蓝色
        legendary = {1, 0.8, 0.2}      -- 金色
    }
    return colors[rarity] or colors.common
end

return UnitCards
