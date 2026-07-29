# Credits & Asset Provenance

Every third-party asset used in this project is logged here with source and license.

## Characters
| Asset | Source | License | Notes |
|---|---|---|---|
| `mouse.glb` model + rig | Pre-existing project asset (origin not documented at time of audit) | Unknown — **verify before shipping** | Rig uses MakeHuman/Rigify-style bone naming (`upperarm01.L`, `spine03`, etc.) |
| `Mouse_Idle`, `Mouse_Walk`, `Mouse_Run`, `Mouse_Talk` animations | Baked into `mouse.glb` | Same as above | |

## UI / Mascot
| Asset | Source | License | Notes |
|---|---|---|---|
| Skeleton main-menu idle sprite (`SkeletonIdle.aseprite`, 9 frames, 145x134) | User-provided, source not stated | Unknown — **verify before shipping** | Extracted to `assets/ui/skeleton_idle/frame_00-08.png` + `skeleton_idle_frames.tres`. Wired into `scenes/main_menu/main_menu.tscn` as a decorative idle mascot (`skeleton_mascot.gd`) — plays its idle loop and flips to face the cursor, no other behavior. |

## Generated content
| Asset | Source | License | Notes |
|---|---|---|---|
| `attack_light_01/02/03`, `attack_heavy_01`, `dodge_roll_fwd`, `hit_react_light/heavy`, `ko_front` | Procedurally generated via `tools/blender_scripts/generate_combat_animations.py` | Project-owned | Fallback path — see below for the preferred retargeted-clip path |

## Pending — animation sources (retargeting in progress)
| Asset | Source | License | Notes |
|---|---|---|---|
| Combat animation clips (retargeted onto mouse.glb's skeleton) | [Quaternius Universal Animation Library](https://quaternius.itch.io/universal-animation-library) | CC0 | Pack sits at `Universal Animation Library[Standard]/` in the project root, not yet imported into Godot. See `assets/characters/mouse/QUATERNIUS_RETARGET_SETUP.md` for the retargeting workflow (Godot's native BoneMap/SkeletonProfileHumanoid system). CC0 doesn't legally require attribution, but this project credits sources regardless per standing convention — update this row with the specific clips used once retargeting is done. |
| 2,548 mocap animation clips (`glTF/01_01.glb`–`94_16.glb`, low-poly rig) | [rancidmilk — Free Character Animations](https://rancidmilk.itch.io/free-character-animations) (converted from [CMU Graphics Lab Motion Capture Database](http://mocap.cs.cmu.edu), BVH source via cgspeed.com) | Free to use/modify/redistribute in a shipped game; **cannot be resold as animations/mocap data on their own, even in converted form**; per CMU's own terms, acknowledgment text is requested (see full text in the pack's `README.txt`) | Downloaded to `Downloads/Anims_Only_glTF_V1.zip` (764 MB, 2,552 files), not yet extracted into the project. Clips are named by CMU subject/trial number, not by content — need to cross-reference CMU's subject catalog to find the punch/hit-react/fall clips actually useful for combat before pulling any into the repo (extracting or copying all 2,548 clips into git is not planned). Same BoneMap/SkeletonProfileHumanoid retarget path as the UAL pack above — its rig won't match mouse.glb's bone names natively. Root motion baked in; pack's README notes deleting the root/hip bone's location keyframes (keep rotation) as a quick fix for game use. |

## Reference only — not shipped in the game
| Asset | Source | License | Notes |
|---|---|---|---|
| Universal Base Characters (Standard) | [Quaternius](https://quaternius.com) | CC0 | 3D mannequin meshes, used only as posing/turntable reference for gang-member concept art and modeling proportions — not imported into the Godot project or shipped. |

## Evaluated, not used
| Asset | Source | License | Notes |
|---|---|---|---|
| Mana Seed Character Base (demo) | [Seliel the Shaper](https://seliel-the-shaper.itch.io/) | Free for commercial/non-commercial use per pack readme | 16-bit pixel-art paper-doll sprites with sword-and-shield combat only. Considered for a 2D sprite pivot, rejected — clashes with GutterRumble's painted concept art and existing 3D cel-shaded pipeline, and has no hand-to-hand combat frames. Not imported. |
| Isometric Character Template | [intellikat](https://intellikat.itch.io) | CC0, attribution requested | Isometric top-down pixel-art sprite template (made for Playdate). Wrong perspective/style for a 3D arena brawler — same rejection reason as Mana Seed. Not imported. |

## Pending — 2D VFX overlays (blood)
| Asset | Source | License | Notes |
|---|---|---|---|
| VFX Blood Concepts (free concept-art preview: 8 FX-only frames, 8 composited frames, 2 gifs, `.ase` source) | [jasontomlee — Blood FX](https://jasontomlee.itch.io/blood-fx) | CC BY 4.0 — commercial use OK, **no redistribution**, attribution to "jasontomlee" / itch.io page requested (not legally required under CC BY's terms as stated, but attribute per project convention regardless) | Sitting unextracted at `Downloads/VFX Blood Concepts/`, not yet imported. This is the free preview tier only. |
| BloodFX Batch 1 (paid tier, 314 kB per itch.io listing) | [jasontomlee — Blood FX](https://jasontomlee.itch.io/blood-fx) | Same as above (CC BY 4.0, commercial OK, no redistribution) | `Downloads/BloodFX Batch 1.rar` — **blocked**, no unrar/7-Zip available on this machine to extract/inspect it yet. |

## Pending — needs your decision before use
| Asset | Source | License | Notes |
|---|---|---|---|
| RPG Effect All Free (hit/impact FX) | [bdragon1727](https://bdragon1727.itch.io/) | Free for non-commercial use; **commercial use requests a voluntary contribution** (no fixed amount); redistribution/resale of the raw assets prohibited | Not yet imported. Confirm you're OK with the commercial-contribution term before this ships in a paid/monetized build. |

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
