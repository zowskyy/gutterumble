# GutterRumble — 10x Completion Build Guide
_Slice-by-slice, AEF Salami Method. Follow in order — each slice is independently shippable._

## How to use this guide
Each slice lists: **what it does**, **files touched**, **why it's Warriors-authentic**, and **verify step**. Tell me a slice number ("do slice 3") and I'll implement it directly — this doc is the map, not a promise of pre-written code.

---

## Phase 0 — Unblock animation (do this first)

### Slice 0: Bake combat animations
**Status:** Script ready — [`tools/blender_scripts/generate_combat_animations.py`](tools/blender_scripts/generate_combat_animations.py)
**What it does:** Procedurally keyframes all 8 missing clips (3 light punches, 1 heavy, dodge, 2 hit-reacts, KO) directly on your existing rig, using your actual bone names (`upperarm01.R`, `spine03`, etc. — confirmed from `mouse.glb`).
**Why it matters:** Every other visual slice below (hit-spark timing, combo pop-text, screen shake sync) reads better once fighters actually swing instead of standing in idle.
**You do:** Open Blender → import `mouse.glb` → run the script → export back over `mouse.glb` with animations on → reimport in Godot.
**Verify:** Run the arena — attacks should show arm swings instead of idle pose during ACTIVE phase.

---

## Phase 1 — Warriors-authentic combat feel

### Slice 1: Hit-spark VFX
**What it does:** Billboarded flash quad (additive shader) spawns at the hit point on every landed hit — white flash for light, orange starburst for heavy, bigger gold burst for KO. This is the single most recognizable Warriors-games visual signature.
**Files:** `assets/shaders/hit_spark.gdshader` (new), `scenes/vfx/hit_spark.tscn` + `.gd` (new, pooled via a `VFXPool` autoload), hook into `player_controller.gd` / `enemy_ai.gd` `_on_hitbox_area_entered`.
**Verify:** Land a hit — a flash should appear at the contact point and fade in ~0.15s.

### Slice 2: Weapon/fist trail
**What it does:** A ribbon trail (via `Line2D`-style 3D mesh or `GPUParticles3D` with `draw_pass` trail) follows the attacking hand during the ACTIVE phase only. PS2 Warriors games used this heavily on every swing to sell weight and speed.
**Files:** `scenes/player/attack_trail.gd` (new component attached to `wrist.R`/`wrist.L` bone via `BoneAttachment3D`).
**Verify:** Attack — a short colored streak should trail the fist during the swing.

### Slice 3: Combo pop-text
**What it does:** Big stylized text ("5 HIT COMBO!") that punches onto screen and scales down — classic Musou juice. `combat_hud.gd` already tracks `_combo_count`; this slice just needs the visual polish (scale-bounce tween, color escalation at combo milestones: white → yellow → red).
**Files:** `scenes/ui/hud/combat_hud.gd` (extend `register_hit()`), add a `Tween` for punch-in/settle/fade.
**Verify:** Land 3+ hits in a row without pause — combo text should pop and scale.

### Slice 4: Musou/special gauge
**What it does:** A meter that fills as you land hits and take damage; at 100% you unlock a screen-clearing special attack (AOE knockback + big radius damage) with a flash-freeze cinematic beat, then meter resets. This is THE Warriors-genre hook — turns "many weak enemies" into a power-fantasy release valve.
**Files:** `autoloads/special_meter.gd` (new — tracks charge, exposes `try_activate()`), `attack_config.gd` (add a `special_attack` entry with huge range/knockback), HUD bar in `combat_hud.gd`.
**Verify:** Land hits until meter fills, press a bound key (e.g. `C`), confirm AOE knockback hits everything nearby.

### Slice 5: Finishing-blow cinematic
**What it does:** On the KO that ends a wave/round, briefly slow time (not full freeze — 0.3x for ~0.6s), zoom camera in on the falling fighter, screen desaturates slightly, then snaps back. `CombatFeel.hit_ko()` already exists — this extends it with a slow-mo window instead of just a shake.
**Files:** `autoloads/combat_feel.gd` (add `finisher_slowmo()`), `scenes/arenas/back_alley/arena_camera.gd` (add a temporary zoom-in target override).
**Verify:** Win a round — the last hit should visibly slow down and the camera should punch in before the result screen.

---

## Phase 2 — Crowd density (the "many fighters" promise)

### Slice 6: Off-screen AI/movement throttling ~~(originally scoped as MultiMesh batching)~~
**Revised during implementation:** `MultiMeshInstance3D` was the original plan, but it only varies transform/color/custom-data across instances of one *static* mesh — it has no support for independent skeletal animation per instance. Batching the fighters this way would freeze every background enemy mid-pose, the opposite of "alive battlefield." Real animated-crowd batching needs Vertex Animation Texture baking (a full shader pipeline, disproportionate here) or a third-party addon (license/provenance review needed). Retargeted to what Godot actually supports correctly for this asset type.
**What it does:** Each `enemy_ai.gd` gets a `VisibleOnScreenNotifier3D`; while off-screen, the AI decision loop and movement are skipped (the phase timer for KO/hit-react still ticks, so state stays correct) — layered independently of `FighterPool`'s `set_physics_process()` so the two don't fight over the same flag.
**Files:** `scenes/enemies/enemy_ai.gd` (extended, not new files).
**Bonus fix found along the way:** `GangSpawner._apply_team_color()` was a silent no-op — it looked for a hardcoded `MouseModel/MeshInstance3D` path that doesn't exist in the actual rig (multiple named surfaces nested under a skeleton, not one flat mesh child). Team colors likely never rendered in Warriors mode until this slice. Fixed with a recursive mesh search filtered to clothing-named surfaces only (tinting eyes/teeth/skin the flat team color would look broken).
**Verify:** Set a wave to `{"team":1,"count":12}` and check `PerfLogger`'s CSV holds ≥60 FPS; confirm enemy gang jackets/pants render in the gang's color, not white.
**Still pending (asset work, not code):** `fighter_lod.gd` exists from an earlier session but was never wired up — it expects `High`/`Med`/`Low` mesh variants under a `Visuals` node that don't exist yet (only one mesh quality level has been authored). Wiring it now would be a harmless no-op; it needs actual low-poly mesh variants exported from Blender first.

### Slice 7: Gang banner HUD
**What it does:** Small portrait-style counter showing "Your Gang: 4" vs "Enemy Gang: 9" with team-colored icons — lets the player read the battlefield at a glance, standard Warriors HUD element.
**Files:** `scenes/ui/hud/combat_hud.gd` (extend), wire to `GangSpawner.active_enemy_count()`.
**Verify:** Warriors mode — counter should tick down as enemies are KO'd.

### Slice 8: Crowd barks (audio)
**What it does:** Random taunt/grunt lines from nearby AI fighters (not the ones currently fighting the player) — sells "many fighters, alive battlefield" even when you're only looking at one duel.
**Files:** `autoloads/audio_manager.gd` (add `play_bark()` with cooldown-per-source), `scenes/enemies/enemy_ai.gd` (call on state transitions).
**You provide:** short grunt/taunt `.ogg` clips in `assets/audio/sfx/barks/`.
**Verify:** With 3+ enemies alive, occasional barks should play from off-camera fighters.

---

## Phase 3 — Progression (make winning matter)

### Slice 9: Gang roster / unlocks
**What it does:** Winning matches earns "rep" (already tracked via `SaveManager.increment_stat`); rep unlocks new gang colors / outfit pieces in the character creator instead of everything being available day one.
**Files:** `autoloads/save_manager.gd` (extend with `unlocked_items` list), `scenes/character_creator/character_creator.gd` (gate `GANG_COLORS` / outfit arrays behind unlock checks).
**Verify:** Fresh save shows locked options; winning 3 matches unlocks the next tier.

### Slice 10: Second arena
**What it does:** A rooftop or subway-platform arena reusing all existing systems (FighterPool, GangSpawner, RoundManager) — proves the architecture generalizes and gives the main menu's "GANG WARS" mode actual variety.
**Files:** New `scenes/arenas/rooftop/rumble_arena_rooftop.tscn` + `.gd` (near-identical to back_alley's, different geometry/lighting/environment preset), `autoloads/game_manager.gd` (add route).
**Verify:** Menu offers arena choice; rooftop plays identically to back alley mechanically.

---

## What ties it together

Slices 1–5 are the highest-value, lowest-risk block — they're additive VFX/feel layers on top of combat that already works, and they're what makes the game *read* as "Warriors-style" instead of "generic brawler." I'd do those first, in order, then reassess whether Phase 2 (crowd density) or Phase 3 (progression) matters more for what you want to ship next.

## Not in scope here (flagged, not forgotten)
- Rollback netcode — needs the Snopek Games addon, separate integration effort
- Full multiplayer matchmaking — `SupabaseManager` stub needs a real backend endpoint
- Licensed sound/music — see `assets/audio/AUDIO_README.md` for free-source links
