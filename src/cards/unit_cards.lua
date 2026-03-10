--[[
    历史人物单位卡牌系统
    每个卡牌代表一个可部署到阵型中的历史人�?
    所有卡牌可以放置在任何位置，放置位置决定其效果
--]]

local UnitCards = {}

-- 卡牌稀有度
UnitCards.RARITY = {
    COMMON = "common",      -- 普�?
    UNCOMMON = "uncommon",  -- 稀�?
    RARE = "rare",          -- 史诗
    LEGENDARY = "legendary" -- 传说
}

-- 位置类型
UnitCards.POSITION = {
    COMMAND = "command",    -- 大营（主�?君主�?
    VANGUARD = "vanguard",  -- 先锋（前线进攻）
    CENTER = "center",      -- 中军（中间传递）
    REAR = "rear"           -- 殿后（后方支援）
}

-- 特殊能力类型
UnitCards.ABILITY = {
    -- 被动能力
    BONUS_ATTACK = "bonus_attack",      -- 攻击加成
    BONUS_DEFENSE = "bonus_defense",    -- 防御加成
    BONUS_TRANSFER = "bonus_transfer",  -- 传递效率加�?
    BONUS_GENERATE = "bonus_generate",  -- 战力生成加成
    
    -- 主动技�?
    CHARGE = "charge",                  -- 冲锋：本回合攻击翻�?
    DEFEND = "defend",                  -- 坚守：本回合减少受到伤害
    AMBUSH = "ambush",                  -- 伏击：偷取敌方战�?
    INSPIRE = "inspire",                -- 鼓舞：相邻单位获得加�?
}

-- ============================================================================
-- 卡牌数据�?
-- ============================================================================

--[[
    所有历史人物卡牌可以放置在任何位置
    放置位置决定其发挥的作用�?
    - 大营：提供全局加成和生命�?
    - 先锋：提供攻击力，负责输�?
    - 中军：提供传递效率，负责中转
    - 殿后：提供战力生成，负责后勤
]]

UnitCards.DATABASE = {
    -- ==================== 刘备 ====================
    {
        id = "liu_bei",
        name = "刘备",
        title = "昭烈皇帝",
        tag = UnitCards.TAG.MONARCH,
        rarity = UnitCards.RARITY.RARE,
        description = "仁德之君，能鼓舞全军士气",
        flavorText = "勿以恶小而为之，勿以善小而不�?,
        -- 不同位置的效�?
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 40,
                abilities = {
                    { type = UnitCards.ABILITY.BONUS_GENERATE, value = 2, desc = "每回合额外生�?点战�? },
                    { type = UnitCards.ABILITY.INSPIRE, value = 1, desc = "所有单位攻击力+1" }
                }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 2, defense = 2,
                abilities = { { type = UnitCards.ABILITY.INSPIRE, value = 1, desc = "相邻单位攻击�?1" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 1, defense = 2,
                abilities = { { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.2, desc = "传递效�?20%" } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 1, defense = 1,
                abilities = { { type = UnitCards.ABILITY.BONUS_GENERATE, value = 3, desc = "战力生成+3" } }
            }
        }
    },
    
    -- ==================== 曹操 ====================
    {
        id = "cao_cao",
        name = "曹操",
        title = "魏武�?,
        tag = UnitCards.TAG.MONARCH,
        rarity = UnitCards.RARITY.RARE,
        description = "乱世奸雄，善于用�?,
        flavorText = "宁教我负天下人，休教天下人负�?,
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 35,
                abilities = {
                    { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.2, desc = "战力传递效�?20%" },
                    { type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "先锋攻击�?1" }
                }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 3, defense = 2,
                abilities = { { type = UnitCards.ABILITY.CHARGE, value = 1.5, desc = "伤害×1.5" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 2, defense = 2,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 2, desc = "偷取敌方2点战�? } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 2, defense = 1,
                abilities = { { type = UnitCards.ABILITY.BONUS_GENERATE, value = 2, desc = "战力生成+2" } }
            }
        }
    },
    
    -- ==================== 孙权 ====================
    {
        id = "sun_quan",
        name = "孙权",
        title = "吴大�?,
        tag = UnitCards.TAG.MONARCH,
        rarity = UnitCards.RARITY.RARE,
        description = "坐断东南，善于守�?,
        flavorText = "生子当如孙仲�?,
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 45,
                abilities = {
                    { type = UnitCards.ABILITY.BONUS_DEFENSE, value = 2, desc = "大营防御+2" },
                    { type = UnitCards.ABILITY.DEFEND, value = 0.3, desc = "受到伤害减少30%" }
                }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 2, defense = 3,
                abilities = { { type = UnitCards.ABILITY.DEFEND, value = 0.2, desc = "受到伤害减少20%" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 1, defense = 3,
                abilities = { { type = UnitCards.ABILITY.BONUS_DEFENSE, value = 1, desc = "全军防御+1" } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 1, defense = 2,
                abilities = { { type = UnitCards.ABILITY.DEFEND, value = 0.25, desc = "减少25%战力损失" } }
            }
        }
    },
    
    -- ==================== 关羽 ====================
    {
        id = "guan_yu",
        name = "关羽",
        title = "武圣",
        tag = UnitCards.TAG.WARRIOR,
        rarity = UnitCards.RARITY.LEGENDARY,
        description = "万人敌，威震华夏",
        flavorText = "玉可碎而不可改其白，竹可焚而不可毁其节",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 35,
                abilities = {
                    { type = UnitCards.ABILITY.BONUS_ATTACK, value = 2, desc = "先锋攻击�?2" },
                    { type = UnitCards.ABILITY.INSPIRE, value = 1, desc = "全军士气+1" }
                }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 4, defense = 2,
                abilities = { { type = UnitCards.ABILITY.CHARGE, value = 2, desc = "伤害×2" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 3, defense = 2,
                abilities = { { type = UnitCards.ABILITY.CHARGE, value = 1.5, desc = "伤害×1.5" } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 2, defense = 2,
                abilities = { { type = UnitCards.ABILITY.INSPIRE, value = 2, desc = "全军攻击�?2" } }
            }
        }
    },
    
    -- ==================== 张飞 ====================
    {
        id = "zhang_fei",
        name = "张飞",
        title = "万人�?,
        tag = UnitCards.TAG.WARRIOR,
        rarity = UnitCards.RARITY.RARE,
        description = "勇猛过人，声若巨�?,
        flavorText = "燕人张飞在此！谁敢与我决一死战�?,
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 38,
                abilities = {
                    { type = UnitCards.ABILITY.BONUS_ATTACK, value = 3, desc = "先锋攻击�?3" }
                }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 5, defense = 1,
                abilities = { { type = UnitCards.ABILITY.BONUS_ATTACK, value = 2, desc = "攻击�?2" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 4, defense = 1,
                abilities = { { type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "攻击�?1" } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 3, defense = 1,
                abilities = { { type = UnitCards.ABILITY.CHARGE, value = 1.3, desc = "伤害×1.3" } }
            }
        }
    },
    
    -- ==================== 赵云 ====================
    {
        id = "zhao_yun",
        name = "赵云",
        title = "常胜将军",
        tag = UnitCards.TAG.WARRIOR,
        rarity = UnitCards.RARITY.RARE,
        description = "一身是胆，单骑救主",
        flavorText = "吾乃常山赵子龙也�?,
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 38,
                abilities = {
                    { type = UnitCards.ABILITY.AMBUSH, value = 1, desc = "每回合偷取敌�?点战�? }
                }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 3, defense = 3,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 2, desc = "偷取敌方2点战�? } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 2, defense = 3,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 1, desc = "偷取敌方1点战�? } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 2, defense = 2,
                abilities = { { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.2, desc = "传递效�?20%" } }
            }
        }
    },
    
    -- ==================== 典韦 ====================
    {
        id = "dian_wei",
        name = "典韦",
        title = "古之恶来",
        tag = UnitCards.TAG.WARRIOR,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "曹操帐下猛将，力大无�?,
        flavorText = "主公快走！我来断后！",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 40,
                abilities = { { type = UnitCards.ABILITY.DEFEND, value = 0.2, desc = "受到伤害减少20%" } }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 4, defense = 2,
                abilities = {}
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 3, defense = 2,
                abilities = {}
            },
            [UnitCards.POSITION.REAR] = {
                attack = 2, defense = 3,
                abilities = { { type = UnitCards.ABILITY.DEFEND, value = 0.15, desc = "减少15%战力损失" } }
            }
        }
    },
    
    -- ==================== 诸葛�?====================
    {
        id = "zhuge_liang",
        name = "诸葛�?,
        title = "卧龙",
        tag = UnitCards.TAG.STRATEGIST,
        rarity = UnitCards.RARITY.LEGENDARY,
        description = "运筹帷幄，决胜千�?,
        flavorText = "鞠躬尽瘁，死而后�?,
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 32,
                abilities = {
                    { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.3, desc = "传递效�?30%" },
                    { type = UnitCards.ABILITY.BONUS_GENERATE, value = 1, desc = "战力生成+1" }
                }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 2, defense = 2,
                abilities = { { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.2, desc = "传递效�?20%" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 2, defense = 2,
                abilities = {
                    { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.4, desc = "传递效�?40%" },
                    { type = UnitCards.ABILITY.BONUS_GENERATE, value = 1, desc = "战力生成+1" }
                }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 1, defense = 2,
                abilities = { { type = UnitCards.ABILITY.BONUS_GENERATE, value = 3, desc = "战力生成+3" } }
            }
        }
    },
    
    -- ==================== 周瑜 ====================
    {
        id = "zhou_yu",
        name = "周瑜",
        title = "美周�?,
        tag = UnitCards.TAG.STRATEGIST,
        rarity = UnitCards.RARITY.RARE,
        description = "曲有误，周郎�?,
        flavorText = "既生瑜，何生�?,
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 33,
                abilities = {
                    { type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "先锋攻击�?1" },
                    { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.15, desc = "传递效�?15%" }
                }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 3, defense = 1,
                abilities = { { type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "相邻单位攻击�?1" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 2, defense = 2,
                abilities = { { type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "相邻单位攻击�?1" } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 2, defense = 1,
                abilities = { { type = UnitCards.ABILITY.INSPIRE, value = 1, desc = "全军攻击�?1" } }
            }
        }
    },
    
    -- ==================== 司马�?====================
    {
        id = "simayi",
        name = "司马�?,
        title = "冢虎",
        tag = UnitCards.TAG.STRATEGIST,
        rarity = UnitCards.RARITY.RARE,
        description = "老谋深算，隐忍不�?,
        flavorText = "夫处世之道，亦即应变之术",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 34,
                abilities = {
                    { type = UnitCards.ABILITY.AMBUSH, value = 2, desc = "每回合偷取敌�?点战�? }
                }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 2, defense = 3,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 2, desc = "偷取敌方2点战�? } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 2, defense = 3,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 3, desc = "偷取敌方3点战�? } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 1, defense = 2,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 1, desc = "偷取敌方1点战�? } }
            }
        }
    },
    
    -- ==================== 荀�?====================
    {
        id = "xun_yu",
        name = "荀�?,
        title = "王佐之才",
        tag = UnitCards.TAG.STRATEGIST,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "曹操�?张良'",
        flavorText = "秉忠贞之志，守谦退之节",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 32,
                abilities = { { type = UnitCards.ABILITY.BONUS_GENERATE, value = 3, desc = "战力生成+3" } }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 1, defense = 2,
                abilities = { { type = UnitCards.ABILITY.BONUS_GENERATE, value = 1, desc = "战力生成+1" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 1, defense = 3,
                abilities = { { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.2, desc = "传递效�?20%" } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 1, defense = 2,
                abilities = { { type = UnitCards.ABILITY.BONUS_GENERATE, value = 4, desc = "战力生成+4" } }
            }
        }
    },
    
    -- ==================== 黄忠 ====================
    {
        id = "huang_zhong",
        name = "黄忠",
        title = "老当益壮",
        tag = UnitCards.TAG.ARCHER,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "百步穿杨，老当益壮",
        flavorText = "竖子欺我年老！吾手中宝刀却不老！",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 36,
                abilities = { { type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "先锋攻击�?1" } }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 3, defense = 1,
                abilities = { { type = UnitCards.ABILITY.BONUS_ATTACK, value = 1, desc = "攻击�?1" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 3, defense = 1,
                abilities = { { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.15, desc = "传递效�?15%" } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 3, defense = 1,
                abilities = { { type = UnitCards.ABILITY.BONUS_ATTACK, value = 2, desc = "攻击�?2" } }
            }
        }
    },
    
    -- ==================== 太史�?====================
    {
        id = "tai_shi_ci",
        name = "太史�?,
        title = "信义笃烈",
        tag = UnitCards.TAG.ARCHER,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "猿臂善射，弦不虚�?,
        flavorText = "大丈夫生于乱世，当带三尺剑立不世之功",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 35,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 1, desc = "每回合偷取敌�?点战�? } }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 3, defense = 1,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 2, desc = "偷取敌方2点战�? } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 3, defense = 0,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 1, desc = "偷取敌方1点战�? } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 3, defense = 0,
                abilities = { { type = UnitCards.ABILITY.AMBUSH, value = 3, desc = "偷取敌方3点战�? } }
            }
        }
    },
    
    -- ==================== 张辽 ====================
    {
        id = "zhang_liao",
        name = "张辽",
        title = "威震逍遥�?,
        tag = UnitCards.TAG.WARRIOR,
        rarity = UnitCards.RARITY.RARE,
        description = "以八百破十万",
        flavorText = "张辽在此，谁敢一战？",
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 37,
                abilities = { { type = UnitCards.ABILITY.CHARGE, value = 1.2, desc = "全军伤害×1.2" } }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 4, defense = 1,
                abilities = { { type = UnitCards.ABILITY.CHARGE, value = 1.5, desc = "伤害×1.5" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 3, defense = 2,
                abilities = { { type = UnitCards.ABILITY.CHARGE, value = 1.3, desc = "传递战力�?.3" } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 3, defense = 1,
                abilities = { { type = UnitCards.ABILITY.CHARGE, value = 1.4, desc = "生成战力×1.4" } }
            }
        }
    },
    
    -- ==================== 姜维 ====================
    {
        id = "jiang_wei",
        name = "姜维",
        title = "幼麟",
        tag = UnitCards.TAG.STRATEGIST,
        rarity = UnitCards.RARITY.UNCOMMON,
        description = "继承武侯遗志",
        flavorText = "臣有一计，可使汉室幽而复�?,
        positionEffects = {
            [UnitCards.POSITION.COMMAND] = {
                hp = 34,
                abilities = { { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.2, desc = "传递效�?20%" } }
            },
            [UnitCards.POSITION.VANGUARD] = {
                attack = 2, defense = 2,
                abilities = { { type = UnitCards.ABILITY.DEFEND, value = 0.2, desc = "受到伤害减少20%" } }
            },
            [UnitCards.POSITION.CENTER] = {
                attack = 2, defense = 2,
                abilities = { { type = UnitCards.ABILITY.BONUS_TRANSFER, value = 0.25, desc = "传递效�?25%" } }
            },
            [UnitCards.POSITION.REAR] = {
                attack = 1, defense = 3,
                abilities = { { type = UnitCards.ABILITY.DEFEND, value = 0.25, desc = "减少25%战力损失" } }
            }
        }
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

-- 获取指定标签的所有卡�?
function UnitCards.getByTag(tag)
    local result = {}
    for _, card in ipairs(UnitCards.DATABASE) do
        if card.tag == tag then
            table.insert(result, card)
        end
    end
    return result
end

-- 获取指定稀有度的所有卡�?
function UnitCards.getByRarity(rarity)
    local result = {}
    for _, card in ipairs(UnitCards.DATABASE) do
        if card.rarity == rarity then
            table.insert(result, card)
        end
    end
    return result
end

-- 获取卡牌在指定位置的效果
function UnitCards.getEffectAtPosition(cardId, position)
    local card = UnitCards.getById(cardId)
    if not card or not card.positionEffects then
        return nil
    end
    return card.positionEffects[position]
end

-- 创建卡牌实例（用于游戏）
function UnitCards.createInstance(cardId, position)
    local template = UnitCards.getById(cardId)
    if not template then
        return nil
    end
    
    -- 获取位置效果
    local effect = position and UnitCards.getEffectAtPosition(cardId, position) or nil
    
    -- 复制卡牌基础数据
    local instance = {
        id = template.id,
        name = template.name,
        title = template.title,
        tag = template.tag,
        rarity = template.rarity,
        description = template.description,
        flavorText = template.flavorText,
        instanceId = tostring(math.random(1000000)),
        position = position,  -- 当前放置位置
    }
    
    -- 应用位置效果
    if effect then
        instance.hp = effect.hp or 10
        instance.maxHp = effect.hp or 10
        instance.currentHp = effect.hp or 10
        instance.attack = effect.attack or 0
        instance.defense = effect.defense or 0
        instance.abilities = effect.abilities or {}
    else
        -- 默认属�?
        instance.hp = 10
        instance.maxHp = 10
        instance.currentHp = 10
        instance.attack = 0
        instance.defense = 0
        instance.abilities = {}
    end
    
    return instance
end

-- 获取位置中文�?
function UnitCards.getPositionName(position)
    local names = {
        command = "大营",
        vanguard = "先锋",
        center = "中军",
        rear = "殿后"
    }
    return names[position] or "未知"
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

