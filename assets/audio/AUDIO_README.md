# Audio Assets

Drop files here. AudioManager will pick them up automatically — no code changes needed.

## sfx/ — Sound effects (.ogg preferred, .wav works)

| Filename | When it plays |
|---|---|
| `hit_light.ogg` | Light attack lands |
| `hit_heavy.ogg` | Heavy attack lands |
| `hit_ko.ogg` | KO blow |
| `dodge.ogg` | Dodge roll starts |
| `ui_confirm.ogg` | Button press |
| `ui_back.ogg` | Back / cancel |
| `countdown.ogg` | Round countdown tick |
| `fight_start.ogg` | "FIGHT!" moment |
| `win.ogg` | Player wins a round |
| `lose.ogg` | Player loses a round |
| `combo_milestone.ogg` | "Gutter Streak" crosses a tier (6, 10, or 15 hits) — a short rising stinger works well |
| `special_activate.ogg` | Player unleashes the special AOE at full gauge |

## sfx/barks/ — Crowd chatter (.ogg)

| Filename | When it plays |
|---|---|
| `bark_01.ogg`, `bark_02.ogg`, `bark_03.ogg` | Random taunt/grunt from an enemy approaching or idling in Warriors mode (not one mid-attack/dodge/hit-react) — picked randomly, one at a time, at most every 4 seconds regardless of wave size |

## music/ — Music loops (.ogg)

| Filename | When it plays |
|---|---|
| `arena_theme.ogg` | In-arena background music |
| `menu_theme.ogg` | Main menu background |

## Free sources (license-friendly)
- https://freesound.org (CC0 / CC-BY — check per file, add to CREDITS if CC-BY)
- https://opengameart.org (filter by CC0)
- https://pixabay.com/sound-effects (free for commercial use)

## Recommended punch SFX pack
Search freesound.org for "punch impact" — filter CC0. Typical setup:
- 2–3 light punch variations (pitch them ±10% in AudioManager for variety)
- 1 heavy thud
- 1 crowd-reaction or bone-crack for KO
