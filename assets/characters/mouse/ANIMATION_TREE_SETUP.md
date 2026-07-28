# Mouse Character — AnimationTree Setup Guide

## 1. Import mouse.glb (one-time)

1. Open Godot, let it import `assets/characters/mouse/mouse.glb` automatically.
2. Select mouse.glb in FileSystem → click **Import** tab.
3. Set **Root Type** → `Node3D` (NOT CharacterBody3D — that's the parent scene's job).
4. Mark these animations as **Loop Mode: Linear**:
   - `Mouse_Idle`
   - `Mouse_Walk`
   - `Mouse_Run`
5. Click **Reimport**.

---

## 2. Swap mesh into fighter.tscn / mouse_enemy.tscn

In `scenes/player/fighter.tscn` (and identically for `mouse_enemy.tscn`):

1. Open the scene in Godot.
2. Delete the placeholder `Mesh` (MeshInstance3D).
3. Drag `assets/characters/mouse/mouse.glb` onto the `Fighter` root node
   → Godot creates an inherited `Node3D` child with the mesh + AnimationPlayer.
4. Rename it to `CharacterMesh` so scripts can find it predictably.

---

## 3. Add AnimationTree node

In the same scene, add a child to `Fighter` root:

- **Type**: `AnimationTree`
- **anim_player**: point to `CharacterMesh/AnimationPlayer` (the GLB's player)
- **active**: ON

Set **Tree Root** to **AnimationNodeStateMachine**.

---

## 4. Build the state machine

Inside the AnimationNodeStateMachine, add these states:

| State name           | Node type            | Clip / sub-tree              |
|----------------------|----------------------|------------------------------|
| `locomotion_idle`    | AnimationNodeAnimation | `Mouse_Idle`               |
| `locomotion_tree`    | AnimationNodeBlendTree | (see § 4a)                 |
| `attack_light_01`    | AnimationNodeAnimation | `Mouse_Idle` (placeholder) |
| `attack_light_02`    | AnimationNodeAnimation | `Mouse_Idle` (placeholder) |
| `attack_light_03`    | AnimationNodeAnimation | `Mouse_Idle` (placeholder) |
| `attack_heavy_01`    | AnimationNodeAnimation | `Mouse_Idle` (placeholder) |
| `dodge_roll_fwd`     | AnimationNodeAnimation | `Mouse_Idle` (placeholder) |
| `hit_react_light`    | AnimationNodeAnimation | `Mouse_Idle` (placeholder) |
| `hit_react_heavy`    | AnimationNodeAnimation | `Mouse_Idle` (placeholder) |
| `ko_front`           | AnimationNodeAnimation | `Mouse_Idle` (placeholder) |

Set **`locomotion_idle`** as the Start state.

### § 4a. locomotion_tree (BlendTree)

Inside `locomotion_tree`, create a **BlendSpace1D**:
- Point `-1` → `locomotion_idle` (Mouse_Idle clip)  →  blend value `0.0`
- Point `0`  → `locomotion_walk` (Mouse_Walk clip)  →  blend value `0.5`
- Point `1`  → `locomotion_run`  (Mouse_Run clip)   →  blend value `1.0`

Connect BlendSpace1D output → `output`.

**Parameter path** the script already writes to:
```
parameters/locomotion_tree/blend_space/blend_position
```

---

## 5. Add transitions between states

Set `xfade_time = 0.10` on all transitions out of locomotion states.
Set `xfade_time = 0.05` on combat state transitions (snappier).
Uncheck **Auto Advance** on all attack/hit/ko transitions — the script calls
`_anim_sm.travel()` explicitly.

---

## 6. When combat animations are ready (Blender)

Add these clips to `mouse.blend` using the naming convention:

```
attack_light_01  (jab — ~12f windup, ~10f active, ~18f recovery)
attack_light_02  (cross — ~10f / 10f / 20f)
attack_light_03  (hook — ~16f / 12f / 30f)
attack_heavy_01  (haymaker — ~28f / 14f / 42f)
dodge_roll_fwd   (~35f total)
hit_react_light  (~20f)
hit_react_heavy  (~30f)
ko_front         (~60f, no loop)
```

Export as GLB. Godot re-imports automatically. Replace placeholder clips in
AnimationTree with the real ones.

### Optional: Call Method Tracks (frame-exact hitboxes)

Instead of relying on the phase timer, add Call Method tracks to each attack clip:
- At the first active frame → call `anim_enter_active()`
- At the first recovery frame → call `anim_enter_recovery()`
- At the last frame → call `anim_attack_end()`

These methods exist in both `player_controller.gd` and `enemy_ai.gd` and
will override the timer immediately when wired up.

---

## Existing mouse.glb animations (available now)

| Clip name   | Frames | Loop |
|-------------|--------|------|
| Mouse_Idle  | 48f    | YES  |
| Mouse_Walk  | 32f    | YES  |
| Mouse_Run   | 20f    | YES  |
| Mouse_Talk  | 48f    | YES  |
