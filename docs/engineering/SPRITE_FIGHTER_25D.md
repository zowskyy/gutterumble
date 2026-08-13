# Sprite Fighter 2.5D (Phase 2 shell)

Hybrid fighter presentation for GutterRumble:

- **3D lane body** — `CharacterBody3D` moves on the XZ plane; collision is a capsule; combat uses the same `Hitbox` / `Hurtbox` / `take_damage` APIs as the skeletal mouse fighter.
- **2D sprites** — `AnimatedSprite3D` (`SpriteVisual`) billboards on fixed Y and draws frames from a horizontal sheet (`player_sheet.png` / `enemy_sheet.png`).
- **Meta JSON** — `fighter_anim_meta.json` maps animation names → frame indices, FPS, loop flags, and optional hit data (`hit_offset`, `hit_radius`, `damaging`).

## Key paths

| Role | Path |
|------|------|
| Player scene | `scenes/player/sprite_fighter.tscn` |
| Enemy scene | `scenes/enemies/sprite_enemy.tscn` |
| Visual script | `scenes/player/sprite_visual.gd` |
| Sheets + meta | `assets/characters/sprite_fighter/` |
| Arena wiring | `rumble_arena_back_alley.gd` preloads the sprite scenes |
| Smoke test | `tools/test_sprite_fighter_25d.gd` |

## Lane + camera

- `lane_mode` locks fighters to a shared `lane_z`; movement is along world X.
- Touch stick Y is **not** inverted (matches keyboard `ui_up`).
- `arena_camera.gd` uses lower height / side distance for SF readability.
- Hitboxes offset on ±X from `fighter_anim_meta.json` while attacking.

No `MouseModel`, no `AnimationTree` on the live path. Controllers detect `SpriteVisual` in `_ready`, call `setup()`, and skip skeletal tree/trail setup.
