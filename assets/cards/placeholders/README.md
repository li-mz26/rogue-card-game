# Card Placeholder Assets

This folder contains layered placeholder resources for the card collection UI.
You can replace any PNG with your production art using the same file names.

## Card Layers

- `bg_canvas.png`: card background base texture
- `portrait_warrior.png`: portrait layer variant A
- `portrait_strategist.png`: portrait layer variant B
- `portrait_guardian.png`: portrait layer variant C
- `overlay_gloss.png`: highlight/gloss overlay
- `frame_common.png`: rarity frame for common cards
- `frame_uncommon.png`: rarity frame for uncommon cards
- `frame_rare.png`: rarity frame for rare cards
- `frame_legendary.png`: rarity frame for legendary cards
- `badge_common.png`: top-right rarity badge C
- `badge_uncommon.png`: top-right rarity badge U
- `badge_rare.png`: top-right rarity badge R
- `badge_legendary.png`: top-right rarity badge L
- `icon_attack.png`: attack stat icon
- `icon_defense.png`: defense stat icon
- `icon_power.png`: HP/power stat icon
- `panel_stats_bg.png`: opaque background for bottom 30% ability-value panel

## Recommended Replacement Size

- Card layer textures: `480 x 680`
- Badge textures: `120 x 120`
- Icon textures: `96 x 96`

## Regeneration Script

If you want to regenerate placeholders:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate_card_placeholders.ps1
```
