# Codex Project Guide (Lua / LÖVE2D)

## 1) Project Purpose

This repository is a LÖVE2D game prototype focused on:

- Deployment phase: choose historical unit cards and place them into formation slots.
- Battle phase: run automated power-transfer chains from command camp to enemy command camp.
- Win condition: reduce enemy command HP to 0.

Current gameplay is closer to a "formation + transfer simulation" than a traditional hand-card roguelike loop.

## 2) How To Run

- Engine: LÖVE 11.4
- Entry: `main.lua`
- Config: `conf.lua`
- Typical run:

```bash
love .
```

## 3) Runtime Flow

Main callbacks in `main.lua`:

- `love.load()` -> `GameState.init()`
- `love.update(dt)` -> `GameState.update(dt)`
- `love.draw()` -> `GameState.draw()`
- Mouse/keyboard are forwarded to `Input` + current game state.

Global state manager in `src/game/gamestate.lua`:

- Declared states: `menu`, `deployment`, `game`, `pause`, `game_over`, `victory`
- Registered handlers only for:
  - `menu` -> `src/ui/menu.lua`
  - `deployment` -> `src/game/deployment.lua`
  - `game` -> `src/game/battle.lua`
  - `pause` -> `src/ui/pause.lua`

So `game_over` / `victory` exist in enum but currently have no dedicated state handlers.

## 4) Module Map

### Actually used in main flow

- `src/game/gamestate.lua`: state routing and transitions
- `src/ui/menu.lua`: start/quit UI
- `src/game/deployment.lua`: card placement UI and deployment result generation
- `src/game/battle.lua`: core combat simulation + rendering
- `src/utils/input.lua`: key/mouse forwarding, ESC pause toggle
- `src/utils/event.lua`: lightweight event bus (currently minimal usage)
- `src/cards/unit_cards.lua`: unit card database and instance factory

### Present but mostly not integrated into this game loop

- `src/player/player.lua`
- `src/enemies/enemy.lua`
- `src/cards/card.lua`

These look like remnants of a Slay-the-Spire-style deck combat prototype, separate from current formation-transfer combat.

## 5) Data Model (Current Combat)

Defined in `src/game/battle.lua`:

- Rows:
  - `COMMAND = 1`
  - `VANGUARD = 2`
  - `CENTER = 3`
  - `REAR = 4`
- Each player:
  - `command` card object
  - `commandHp`, `maxCommandHp`
  - `units[rowType]` (sparse-friendly arrays)
  - `basePowerGeneration` (default 5 + command bonuses)
  - `rowCounts` for variable row sizes
- Transfer-related stats on units:
  - `sendPower`
  - `recvPower`
  - `interceptPower`
  - `powerMod`
  - `tags` (dynasty/surname/origin)

Card source:

- `src/cards/unit_cards.lua` has static `DATABASE`
- `createInstance(cardId, position)` combines base card info + position effect + derived transfer stats

## 6) Deployment Phase

File: `src/game/deployment.lua`

Responsibilities:

- Choose command card.
- Fill vanguard/center/rear slots (count adjustable 1..5).
- Maintain click areas for:
  - slots
  - card list items
  - row count +/- buttons
  - action buttons
- Buttons:
  - Auto deploy
  - Clear
  - Confirm

On confirm:

1. `Deployment.getDeploymentResult()`
2. `Battle.setDeploymentData({ player1 = result, player2 = nil })`
3. `GameState.switch("game")`

When `player2` is nil, battle auto-generates AI deployment by calling `Deployment.autoDeploy()`.

## 7) Battle Phase

File: `src/game/battle.lua` (~1000+ lines)

High-level turn sequence:

1. `Battle.startTurn()` sets phase to `ready` and waits for user click.
2. `Battle.startRound()` triggers `Battle.startTransfer()`.
3. `Battle.startTransfer()`:
   - Compute total packets from `basePowerGeneration`.
   - For each packet:
     - Command -> Rear (can be intercepted by enemy vanguard)
     - Rear -> Center (can be intercepted by enemy center)
     - Center -> Vanguard (can be intercepted by enemy rear)
     - Vanguard -> Enemy Command (final damage application)
   - Each hop is animated by moving power balls.
4. `Battle.update()` monitors animation completion in transfer phase.
5. `Battle.checkTransferComplete()`:
   - If defender HP <= 0 -> phase `victory`
   - Else `Battle.endTurn()`, switch active player, delay, then next turn

Targeting/transfer logic details:

- Target slot selection is weighted (`chooseTargetByDistribution`) using recvPower, powerMod, and tag synergy.
- Success rate is probabilistic (`calcTransferSuccessRate`), clamped to `[0.05, 0.98]`.
- Power amount can be scaled (`applyPowerModifier`).

## 8) Input Behavior

`src/utils/input.lua`:

- ESC toggles between `game` <-> `pause`.
- Mouse events are broadcast via `Event.trigger(...)`.
- State-specific mouse handling is done through `GameState.mousepressed/...`.

## 9) Known Gaps / Risks (Important For Codex)

1. `battle.lua` references `TEST_MODE` and `roundCounter`, but no clear local definitions were found in file scope.
2. `battle.lua` UI click path references `Battle.deployPower(...)` and checks `currentPhase == "deploy"`, but this function/phase flow is not clearly present in current turn pipeline.
3. Declared game states `GAME_OVER` and `VICTORY` are not wired as standalone state modules in `GameState.init()`.
4. `README.md` and parts of comments appear to have encoding artifacts; source logic is readable but Chinese comments are partially garbled in some environments.
5. There are two design directions mixed in repository:
   - Formation transfer combat (active)
   - Deck/hand combat (`player.lua`, `enemy.lua`, `card.lua`, mostly inactive)

## 10) Suggested Working Strategy For Future Codex Sessions

If adding features, start from this order:

1. `src/game/battle.lua`
2. `src/game/deployment.lua`
3. `src/cards/unit_cards.lua`
4. `src/game/gamestate.lua`
5. UI files in `src/ui/`

If refactoring, consider separating:

- `battle_simulation.lua` (math/logic only)
- `battle_render.lua` (draw)
- `battle_input.lua` (mouse/buttons)

This will make testing and feature iteration much easier.

