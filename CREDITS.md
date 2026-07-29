# Credits & Asset Provenance

Every third-party asset used in this project is logged here with source and license.

## Characters
| Asset | Source | License | Notes |
|---|---|---|---|
| `mouse.glb` model + rig | Pre-existing project asset (origin not documented at time of audit) | Unknown — **verify before shipping** | Rig uses MakeHuman/Rigify-style bone naming (`upperarm01.L`, `spine03`, etc.) |
| `Mouse_Idle`, `Mouse_Walk`, `Mouse_Run`, `Mouse_Talk` animations | Baked into `mouse.glb` | Same as above | |

## Generated content
| Asset | Source | License | Notes |
|---|---|---|---|
| `attack_light_01/02/03`, `attack_heavy_01`, `dodge_roll_fwd`, `hit_react_light/heavy`, `ko_front` | Procedurally generated via `tools/blender_scripts/generate_combat_animations.py` | Project-owned | Fallback path — see below for the preferred retargeted-clip path |

## Pending — Quaternius Universal Animation Library
| Asset | Source | License | Notes |
|---|---|---|---|
| Combat animation clips (retargeted onto mouse.glb's skeleton) | [Quaternius Universal Animation Library](https://quaternius.itch.io/universal-animation-library) | CC0 | **Not yet imported.** Decided on as the preferred animation source over the procedural script — see `assets/characters/mouse/QUATERNIUS_RETARGET_SETUP.md` for the retargeting workflow (Godot's native BoneMap/SkeletonProfileHumanoid system). CC0 doesn't legally require attribution, but this project credits sources regardless per standing convention — update this row with the specific clips used once retargeting is done. |

## Audio
| Asset | Source | License | Notes |
|---|---|---|---|
| `hit_light.wav`, `hit_heavy.wav` | [Mixkit](https://mixkit.co) sound effects | Mixkit free license — no attribution required, logged here per project convention regardless | User-sourced, added 2026-07-29 |
| `hit_ko.mp3`, `dodge.mp3`, `ui_confirm.mp3`, `countdown.mp3`, `fight_start.mp3`, `win.mp3`, `lose.mp3`, `special_activate.mp3` | ElevenLabs Sound Effects (AI-generated) | Per user's ElevenLabs plan — verify commercial-use terms for that specific plan before public release | User-generated, added 2026-07-29 |
| `barks/bark_01.mp3`–`bark_05.mp3` | ElevenLabs Sound Effects (AI-generated voice lines, male/female taunter) | Same as above | User-generated, added 2026-07-29 |
| `music/arena_theme.mp3`, `music/menu_theme.mp3` | User-provided | Unknown — **verify source/license before shipping**, not documented at time of import | Added 2026-07-29 |
| `combo_milestone.ogg`, `ui_back.mp3` | — | — | Not yet generated; `ui_back` currently reuses `ui_confirm.mp3` in code as a placeholder |

See `assets/audio/AUDIO_README.md` for the full wiring table and a list of unused
generated audio available for future expansion.

## Textures
| Asset | Source | License | Notes |
|---|---|---|---|
| `arena_urban_01-04` concept/textures | Pre-existing project asset | Unknown — **verify before shipping** | |

---

**Action item:** The `mouse.glb` character and arena textures predate this audit and have no documented source. Before any public release, confirm their origin and license, or replace them with assets that have clear provenance.
