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
| `attack_light_01/02/03`, `attack_heavy_01`, `dodge_roll_fwd`, `hit_react_light/heavy`, `ko_front` | Procedurally generated via `tools/blender_scripts/generate_combat_animations.py` | Project-owned | Authored by this build process, no external source |

## Audio
_None yet — see `assets/audio/AUDIO_README.md` for recommended free/CC0 sources (freesound.org, opengameart.org, pixabay.com). Log each file here once added, per the source's license terms._

## Textures
| Asset | Source | License | Notes |
|---|---|---|---|
| `arena_urban_01-04` concept/textures | Pre-existing project asset | Unknown — **verify before shipping** | |

---

**Action item:** The `mouse.glb` character and arena textures predate this audit and have no documented source. Before any public release, confirm their origin and license, or replace them with assets that have clear provenance.
