# Rogue Card Game

一个使�?LÖVE2D 开发的 Roguelike 卡牌游戏�?

## 游戏简�?

这是一款受《杀戮尖塔�?Slay the Spire) 启发�?Roguelike 卡牌游戏。玩家需要通过构建强大的牌组、收集遗物、战胜各种敌人，最终通关游戏�?

## 特�?

- 🎴 **卡牌构筑**: 收集和组合各种卡牌，打造属于你的独特牌�?
- 🗺�?**Roguelike 地图**: 随机生成的地图，每次游戏都是全新体验
- 👹 **多样化敌�?*: 各种具有独特能力的敌人等待挑�?
- 🎁 **遗物系统**: 收集强大的遗物来增强你的能力
- ⚔️ **策略战斗**: 深度的回合制战斗系统

## 安装和运�?

### 前提条件

- 安装 [LÖVE2D](https://love2d.org/) 11.4 或更高版�?

### 运行游戏

```bash
# 方式 1: 直接拖拽文件夹到 love.exe
# 将整个项目文件夹拖拽�?love.exe �?

# 方式 2: 使用命令�?
love path/to/rogue-card-game

# 方式 3: 打包运行 (Windows)
cd path/to/rogue-card-game
zip -r ../rogue-card-game.love .
love ../rogue-card-game.love
```

## 项目结构

```
rogue-card-game/
├── main.lua              # 游戏入口
├── conf.lua              # LÖVE 配置
├── README.md             # 项目说明
├── src/                  # 源代�?
�?  ├── game/            # 游戏核心逻辑
�?  �?  ├── gamestate.lua   # 游戏状态管�?
�?  �?  └── battle.lua      # 战斗系统
�?  ├── cards/           # 卡牌系统
�?  �?  └── card.lua        # 卡牌基类
�?  ├── player/          # 玩家相关
�?  �?  └── player.lua      # 玩家�?
�?  ├── enemies/         # 敌人相关
�?  �?  └── enemy.lua       # 敌人基类
�?  ├── ui/              # 用户界面
�?  �?  ├── menu.lua        # 主菜�?
�?  �?  └── pause.lua       # 暂停菜单
�?  └── utils/           # 工具函数
�?      ├── input.lua       # 输入管理
�?      └── event.lua       # 事件系统
├── assets/              # 资源文件
�?  ├── images/         # 图片资源
�?  ├── audio/          # 音频资源
�?  └── fonts/          # 字体文件
└── lib/                 # 第三方库
```

## 操作说明

| 按键 | 功能 |
|------|------|
| 鼠标左键 | 选择卡牌/点击按钮 |
| ESC | 暂停游戏/返回 |

## 开发计�?

- [x] 基础项目结构
- [x] 游戏状态管�?
- [x] 卡牌系统
- [x] 玩家系统
- [x] 敌人系统
- [ ] 遗物系统
- [ ] 地图系统
- [ ] 商店系统
- [ ] 事件系统
- [ ] 音效和音�?
- [ ] 美术资源

## 贡献

欢迎提交 Issue �?Pull Request�?

## 许可�?

MIT License

## 致谢

- [LÖVE2D](https://love2d.org/) - 优秀�?2D 游戏框架
- [Slay the Spire](https://www.megacrit.com/) - 灵感来源
