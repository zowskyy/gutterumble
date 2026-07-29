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
_None yet — see `assets/audio/AUDIO_README.md` for recommended free/CC0 sources (freesound.org, opengameart.org, pixabay.com). Log each file here once added, per the source's license terms._

## Textures
| Asset | Source | License | Notes |
|---|---|---|---|
| `arena_urban_01-04` concept/textures | Pre-existing project asset | Unknown — **verify before shipping** | |

---

**Action item:** The `mouse.glb` character and arena textures predate this audit and have no documented source. Before any public release, confirm their origin and license, or replace them with assets that have clear provenance.
