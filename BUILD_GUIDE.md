# GUTTERUMBLE — Slide-by-Slice Build Guide

**Status**: Main Menu ✅ | Character Creator ✅ | Back Alley Arena ✅ | Combat Core ⚠️ | Remaining Content ❌

**Platform**: Godot 4.7 Mobile (Android) | **Target**: ~15–20 playable hours | **Weapon Pool**: 5 types | **Arenas**: 6 total (1 done, 5 pending)

---

## Phase 1: Combat Polish & Validation ⏱️ ~3–4 days

### What's Done
- Basic player controller (movement, attacks)
- Combat manager (hitbox detection)
- Attack config (weapon stats)
- One working arena (back_alley)

### What You're Building
Single-player test loop: start game → customize character → fight AI → loop with different enemies.

### Slice 1.1: AI Enemy System
**Goal**: Player can fight a challenging AI opponent in back_alley

- [ ] **Create `scenes/enemies/enemy_ai.gd`** — Base AI class
  - Health, stamina, weapon selection
  - State machine: idle → approach → attack → dodge
  - Damage feedback (knockback, invulnerability frames)
- [ ] **Weapon combo logic** — Each weapon has 1–3 attack chains
  - Bat: slow, heavy (close range)
  - Chain: medium speed, mid range
  - Knife: fast, low damage (close)
  - Pipe: medium speed, good range
  - Brass knuckles: very fast, very short range
- [ ] **Difficulty modulation** — AI skill slider (easy/normal/hard)
- [ ] **Test**: Play 3–5 rounds, verify no infinite loops or crashes

**Deliverable**: Enemy AI opponent that makes the back_alley arena playable.

---

### Slice 1.2: Combat Feedback & Polish
**Goal**: Combat feels responsive and rewarding

- [ ] **Hit feedback** — Visual/audio cues
  - Screen shake on heavy hits (bat/pipe)
  - Damage numbers (3D floating text)
  - Knockback distance based on weapon/stats
- [ ] **Sound design** — SFX integration (if audio assets exist)
  - Attack swings, hits, grunts, damage
- [ ] **Animation polish** — Weapon attack animations
  - Reuse back_alley player rig if available, or simplify to placeholder capsules
- [ ] **HUD feedback** — Health bars (player + opponent), stamina, weapon indicator

**Deliverable**: Combat feels weighty and responsive. Player knows when they hit and when they're hurt.

---

### Slice 1.3: Game Loop & Victory/Defeat
**Goal**: One complete fight loop works end-to-end

- [ ] **Match state machine**
  - `setup` → `in_progress` → `victory`/`defeat` → `results_screen` → main menu
- [ ] **Victory/Defeat screens**
  - Show match summary (damage dealt, damage taken, weapon used)
  - Replay option (same arena, different AI character)
  - Main menu button
- [ ] **Character respawn** — Reset player position, health, stamina between fights
- [ ] **Test**: Emulate 10 consecutive fights, verify no state leaks or soft locks

**Deliverable**: You can boot the game, customize a character, fight the AI, and cleanly return to menu.

---

## Phase 2: Content Pipeline & Asset Gen ⏱️ ~2–3 days

### What You're Building
Automated asset generation (arena variations, outfit combinations) so you can populate content quickly.

### Slice 2.1: Asset Directory Structure & Naming
**Goal**: Organize all modular assets for programmatic generation

```
assets/
├── arenas/
│   ├── back_alley/           # DONE: textures + background model
│   ├── subway_platform/      # Placeholder: blank textures + geo
│   ├── rooftop/
│   ├── warehouse/
│   ├── parking_garage/
│   └── burning_lot/
├── characters/
│   ├── base/                 # Base human rig (from mouse rig or placeholder)
│   ├── headwear/
│   │   ├── cap_black.glb
│   │   ├── cap_red.glb
│   │   ├── hood_grey.glb
│   │   └── ...
│   ├── torso/
│   │   ├── jacket_leather_brown.glb
│   │   └── ...
│   ├── hands/                # Gloves, bare, etc.
│   ├── legs/                 # Pants variants
│   ├── footwear/             # Boots, shoes, sneakers
│   └── accessories/          # Chains, bands, etc.
└── weapons/
	├── bat_wood.glb
	├── bat_metal.glb
	├── chain_steel.glb
	└── ...
```

- [ ] **Verify folder structure** — Create placeholders for missing categories
- [ ] **Naming convention** — `{category}_{name}_{variant}.glb`
- [ ] **Manifest audit** — Ensure `outfit_manifest.json` and `weapon_manifest.json` list all assets
- [ ] **Import settings** — Verify all GLBs import with correct scale/pivot in Godot

**Deliverable**: Asset folders are organized and ready for auto-generation scripts.

---

### Slice 2.2: Programmatic Character Assembly
**Goal**: Given customization choices → spawn rigged, textured character in scene

Leverage existing Python scripts (`generate_complete_gutterumble.py`, `generate_content_pipeline_fixed.py`).

- [ ] **Create `scenes/character_assembler.gd`** — Godot runtime assembler
  - Input: customization dict (headwear, torso, legs, etc.)
  - Load base human rig + mount modular assets on sockets
  - Apply outfit tinting (colorize torso/legs/boots)
  - Return: fully dressed character ready to spawn
- [ ] **Socket verification** — Base rig has named attachment points
  - `Head`, `TorsoAttach`, `Hand_L`, `Hand_R`, `Legs`, `Feet`, `AccessoryNeck`
- [ ] **LOD prep** — Character assembly runs at load, not every frame
- [ ] **Test**: Assemble 10 random outfit combos, verify no overlaps/deformation

**Deliverable**: Character creator can select outfit → character renders correctly in-game.

---

### Slice 2.3: Arena Variation Generator
**Goal**: Each arena has 2–3 lighting/time-of-day variants to reduce repetition

- [ ] **Blender export pipeline** — If doing 3D arenas:
  - Base geo + colliders (exported as `arena_base.glb`)
  - 3 material sets per arena: daytime, evening, night
- [ ] **Godot arena loader** — `scenes/arenas/arena_loader.gd`
  - Load arena geo, apply material variant
  - Spawn spawn points for player + AI
  - Set ambient lighting, skybox, post-processing
- [ ] **Arena instantiation** — Create template:
  ```gdscript
  @onready var arena = load_arena("subway_platform", variant="evening")
  ```
- [ ] **Test**: Load each arena variant, verify colliders and lighting

**Deliverable**: All 6 arenas have basic geometry and at least 2 lighting states.

---

## Phase 3: Full Arena Rollout ⏱️ ~4–5 days

### What You're Building
Build the remaining 5 arenas (subway, rooftop, warehouse, parking garage, burning lot).

### Slice 3.1: Subway Platform
**Goal**: Working subway arena with player spawns, colliders, visual identity

**Asset Checklist:**
- [ ] Geo: platform, rails, tunnel walls, ads/tiling
- [ ] Lighting: fluorescent overhead (harsh shadows)
- [ ] Textures: concrete, metal, rust, LED ads
- [ ] Spawn points: player corner, AI corner

**Integration:**
- [ ] Add to `GameManager.gd` as `go_to_subway_platform()`
- [ ] Test: load arena → customize player → fight → victory screen

---

### Slice 3.2: Rooftop
**Goal**: Wide-open arena with edge hazards and verticality

**Asset Checklist:**
- [ ] Geo: building top, AC units, ledges, edge barriers
- [ ] Skybox: city skyline at sunset
- [ ] Lighting: warm 3-point (sunset direction)
- [ ] Textures: gravel, tar, metal ductwork
- [ ] Optional: fall damage if players go off ledge (medium damage, teleport back)

---

### Slice 3.3: Warehouse
**Goal**: Industrial arena with crates, movement variety

**Asset Checklist:**
- [ ] Geo: shipping containers, wooden crates, industrial floor
- [ ] Obstacle layout: tight corridor sections + open area
- [ ] Lighting: cool, diffuse (overcast warehouse)
- [ ] Textures: corrugated metal, wood, paint

---

### Slice 3.4: Parking Garage
**Goal**: Multi-level arena (optional verticality)

**Asset Checklist:**
- [ ] Geo: concrete ramps, car bays, pillars
- [ ] Lighting: fluorescent + neon signs (cyberpunk vibe)
- [ ] Textures: concrete, paint lines, oil stains, neon
- [ ] Spawn points: different levels (allows ramp chases)

---

### Slice 3.5: Burning Lot
**Goal**: Highest difficulty arena with environmental hazard (fire)

**Asset Checklist:**
- [ ] Geo: abandoned lot, burnt vehicles, debris
- [ ] Fire hazard zones (low-damage DoT, visual warning)
- [ ] Lighting: orange firelight + dark shadows
- [ ] Textures: rust, charred metal, dirt
- [ ] Enemy spawn: toughest AI difficulty

---

### Slice 3.6: Arena Selection Menu & Progression
**Goal**: Main menu → select arena → select opponent difficulty → fight

- [ ] **Arena selection UI** — Show 6 arenas, difficulty slider, preview
- [ ] **Difficulty scaling** — Easy/Normal/Hard modulates AI stats
  - Easy: AI slower, lower health
  - Normal: baseline (current)
  - Hard: faster, more stamina, better combos
- [ ] **Win tracking** — Store matches won/lost per arena per difficulty
- [ ] **Unlock logic** (optional): Early arenas always available, later arenas unlock after X wins

**Deliverable**: You can select any arena, fight AI at chosen difficulty, and return to menu.

---

## Phase 4: Progression & Multiplayer Setup ⏱️ ~3–4 days

### Slice 4.1: Player Profile & Stats Persistence
**Goal**: Save player name, match history, best weapon, rank

- [ ] **Local profile storage** — Godot's ConfigFile or JSON
  - Player name, total wins/losses, wins per arena, preferred weapon
- [ ] **Supabase integration** — Sync profile online (if backend is ready)
  - Create tables: `players` (id, name, wins, losses), `matches` (player_id, arena, result, opponent_name)
- [ ] **Leaderboard prep** — Query top 100 players by wins (don't render yet, just data)

**Deliverable**: Exit game, restart → profile and stats persist.

---

### Slice 4.2: Match Replay & Statistics
**Goal**: After match, show detailed stats

- [ ] **Match summary screen**
  - Damage dealt / taken
  - Hits landed / missed
  - Weapon used, final opponent name
  - Duration
  - Replay button, try again, back to menu
- [ ] **Season stats** — Cumulative: total wins, KDR, favorite weapon, favorite arena

**Deliverable**: Complete a match, see comprehensive stats.

---

### Slice 4.3: Lobby & Opponent Selection
**Goal**: (Multiplayer prep) Allow player to select NPC opponent name from DB

**This is a bridge to multiplayer — not full PvP yet, but framework is ready.**

- [ ] **Opponent selector UI**
  - Show list of top players (or random selection)
  - Option: fight AI mimic of that player's stats
- [ ] **NPC character gen** — When fighting a "named" opponent:
  - Load their saved outfit from DB
  - Spawn with their typical weapon + stats
  - AI plays with their difficulty level
- [ ] **Match recording** — Log match (player A vs player B setup) to DB

**Deliverable**: You can "challenge" top players (offline, AI simulated).

---

## Phase 5: Polish & Launch Ready ⏱️ ~2–3 days

### Slice 5.1: Main Menu Refinement
**Goal**: Polished entry point with clear flow

- [ ] **Main menu screens**
  - Title screen → New Game / Load Profile / Settings / Quit
  - New Game → Character Creator → Arena Select → Fight
  - Settings: sound volume, difficulty default, graphics quality
- [ ] **Music/ambience** — Title screen music, arena ambient loops
- [ ] **Visual polish** — Title animation, button transitions, fade effects

---

### Slice 5.2: UI Consistency & Accessibility
**Goal**: All screens follow same design language, readable on mobile

- [ ] **Font sizing** — Test on phone/tablet, verify text is readable
- [ ] **Touch target sizes** — Buttons ≥ 48x48dp for mobile
- [ ] **Color contrast** — WCAG AA or better
- [ ] **Pause menu** — Accessible mid-fight

**Deliverable**: Game feels cohesive and responsive on target device.

---

### Slice 5.3: Performance & Build
**Goal**: Game runs at 60fps on target Android device, APK builds

- [ ] **Profiling** — Check performance in combat (heavy particles/effects)
- [ ] **Draw call optimization** — Batching, LOD for characters
- [ ] **Memory** — Monitor during long play sessions (no leaks)
- [ ] **Export settings** — Android APK export, app signing
- [ ] **Install & test on device** — Verify touch controls, network latency

**Deliverable**: APK installs and runs smoothly on Android target.

---

### Slice 5.4: Polish Pass & Bug Hunt
**Goal**: Fix small issues, enhance feel

- [ ] **Visual tweaks** — Weapon animations, impact effects, particle polish
- [ ] **Audio tweaks** — SFX timing, volume balancing
- [ ] **Game feel** — Knockback ranges, attack recovery times, stamina drain
- [ ] **Regression test** — Play 20+ matches, different arenas/characters, look for crashes/exploits

**Deliverable**: No known bugs, game feels "done."

---

## Phase 6: Optional Post-Launch Content ⏱️ Future

### 6.1: Cosmetics & Battlepasses
- Rare outfit combinations (cosmetic skins)
- Weapon skins (visual variants, same stats)
- Seasonal battlepass with challenges

### 6.2: Real Multiplayer (PvP)
- WebSocket or Netcode4 for live PvP
- Ranked ladder with ELO
- Clan/team support

### 6.3: Seasonal Content
- Monthly arena themes
- Limited-time events
- Boss encounters

---

## Implementation Checklist (Quick Reference)

### Phase 1 (Week 1, Days 1–4)
- [ ] AI enemy system (states, attacks, health)
- [ ] Combat feedback (hit effects, damage numbers, sound)
- [ ] Victory/defeat flow + results screen
- [ ] **Deliverable**: 1v1 fights work end-to-end in back_alley

### Phase 2 (Week 1–2, Days 5–7)
- [ ] Asset organization + naming convention
- [ ] Character assembly GDScript (modular outfit mounting)
- [ ] Arena loader for variants
- [ ] **Deliverable**: Character creator works, all 6 arenas have basic geo

### Phase 3 (Week 2, Days 8–12)
- [ ] Subway, rooftop, warehouse, parking garage, burning lot arenas
- [ ] Arena select menu + difficulty slider
- [ ] Spawn points, colliders, lighting per arena
- [ ] **Deliverable**: All 6 arenas playable, arena select menu works

### Phase 4 (Week 2–3, Days 13–16)
- [ ] Profile persistence (local + Supabase)
- [ ] Match stats screen
- [ ] Opponent selector (name-based), NPC mimic generation
- [ ] **Deliverable**: Stats persist, leaderboard framework ready

### Phase 5 (Week 3, Days 17–19)
- [ ] Main menu polish + settings
- [ ] UI accessibility & consistency
- [ ] Performance optimization + Android APK build
- [ ] Bug hunt & polish pass
- [ ] **Deliverable**: Ready for launch, APK tested on device

---

## Parallel Tracks (Can Run Simultaneously)

**Art & Audio** (can happen in parallel with Phase 1–3):
- [ ] Model remaining arena geo in Blender
- [ ] Create outfit variants (GLB exports)
- [ ] Record weapon SFX
- [ ] Compose title + arena ambient tracks

**Networking** (can happen in parallel with Phase 2–4):
- [ ] Test Supabase player table schema
- [ ] Implement match logging
- [ ] Test cloud function for leaderboard queries

---

## Success Criteria

**At end of Phase 3**: Game is fully playable, all content accessible, ready for alpha testing.

**At end of Phase 5**: Game feels polished, no crashes, runs at 60fps, ready for soft launch.

---

## Time Estimate

- **Phase 1**: 3–4 days
- **Phase 2**: 2–3 days
- **Phase 3**: 4–5 days (asset creation is the bottleneck; can parallelize)
- **Phase 4**: 3–4 days
- **Phase 5**: 2–3 days
- **Total**: 14–19 days (≈ 2.5–3.5 weeks)

If you parallelize art/audio with dev, you can ship in **2.5 weeks**.

---

## Notes

- **Modular by design**: Each arena is independent. Finish one completely before moving to the next.
- **Test early**: After each slice, boot the game and verify the loop works.
- **Asset bottleneck**: If art is slower, Phases 1–2 can stay ahead of schedule. Stub assets (simple geometry) are fine for early tests.
- **Multiplayer**: Framework ready after Phase 4, but full PvP can be post-launch content.

---

**Next Step**: Start Phase 1, Slice 1.1. Set a timer for 1 day, get AI enemy working, then playtest.
