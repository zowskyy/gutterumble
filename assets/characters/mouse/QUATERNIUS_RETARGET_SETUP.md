# Retargeting Quaternius Animations onto the Mouse Rig

Uses Godot 4's **built-in retargeting system** (`BoneMap` + `SkeletonProfileHumanoid`)
— verified against Godot's own devblog before writing this, not assumed. This
runs entirely in the Godot editor. **No Blender required for this path.**

Source: [Quaternius Universal Animation Library](https://quaternius.itch.io/universal-animation-library) — CC0.
Logged in [`CREDITS.md`](../../../CREDITS.md) once actually imported.

## Why this instead of the procedural Blender script

`tools/blender_scripts/generate_combat_animations.py` (already in this repo)
generates placeholder motion procedurally — correct timing, but visibly
mechanical no matter how much easing/anticipation is layered on. Real
animated clips from Quaternius will look more human. Both approaches produce
clips with the **same final names** (`attack_light_01`, `hit_react_heavy`,
etc.), so `AnimationTreeBuilder.gd` needs zero code changes either way — it
already expects exactly these clip names and doesn't care how they were made.

## Step 1 — Download

Get the pack from the itch.io link above. You want the **Blender source
files or a glTF/FBX export** — whichever Quaternius provides for their
animation-only files. Drop it somewhere outside `res://` for now (e.g. a
scratch folder) — you'll only pull the finished retargeted clips into the
project.

## Step 2 — Import both rigs into the SAME Godot project

**Mouse (target skeleton — the one that ends up in-game):**
1. Select `assets/characters/mouse/mouse.glb` in the FileSystem dock.
2. Import tab → Root Type stays as-is (this is your gameplay character).
3. Import As: **Scene** (this is the character that actually gets used).

**Quaternius pack (animation source only):**
1. Copy the Quaternius rig+animation file into the project temporarily,
   e.g. `assets/characters/_quaternius_source/` (prefix with `_` so it's
   easy to spot as temporary/reference-only, delete after retargeting).
2. Import tab → Import As: **Animation Library** (you only want its
   animation data, not its mesh — you're putting Quaternius *motion* onto
   the *mouse* skeleton, not swapping characters).

## Step 3 — Map both rigs to `SkeletonProfileHumanoid`

This is the actual retargeting mechanism. In each import's settings panel,
find the **Retarget** section and assign `SkeletonProfileHumanoid`. Godot
auto-maps bones whose names contain recognizable English humanoid terms
(hips, shoulder, arm, leg, foot, etc.) — the rest need manual assignment via
the **BoneMap** editor (a visual bone-picker in the import dock).

### My best-guess starting map for the mouse rig

I read `mouse.glb`'s actual bone names earlier this session (they're
MakeHuman/Rigify-style) and this mapping should be correct for the primary
chain, but **verify visually in Godot's BoneMap editor before trusting it**
— I can't see bone orientation/roll from a text dump, only names:

| Mouse bone | SkeletonProfileHumanoid role |
|---|---|
| `root` | Root |
| `spine01` | Hips or Spine (whichever sits at the base — check in-editor) |
| `spine02`–`spine03` | Spine / Chest |
| `spine04`–`spine05` | UpperChest (if the profile wants a 5th spine bone, otherwise leave unmapped) |
| `neck01`–`neck03` | Neck (map the one closest to a single-neck-bone profile; extras can stay unmapped) |
| `head` | Head |
| `clavicle.L`/`.R` | Shoulder.L/.R |
| `upperarm01.L`/`.R` | UpperArm.L/.R |
| `lowerarm01.L`/`.R` | LowerArm.L/.R |
| `wrist.L`/`.R` | Hand.L/.R |
| `upperleg01.L`/`.R` | UpperLeg.L/.R |
| `lowerleg01.L`/`.R` | LowerLeg.L/.R |
| `foot.L`/`.R` | Foot.L/.R |

Bones with a `02` suffix (`upperarm02`, `lowerarm02`, `upperleg02`) look like
twist/secondary bones from the naming pattern — they likely have no
corresponding humanoid profile role and can stay unmapped; the retarget
should still look correct off the primary rotation-bearing bones alone.
`pelvis.L`/`pelvis.R` are ambiguous from the name alone (could be hip-socket
twist bones) — I deliberately avoided guessing at these in the procedural
script for the same reason; check their position in the Blender/Godot
viewport before mapping them to anything.

Repeat the same profile assignment on the Quaternius import so both rigs
share the same target profile — that shared profile is what makes the
retarget possible.

## Step 4 — Pick source clips and rename to match the state machine

`AnimationTreeBuilder.gd` expects exactly these 8 names:

```
attack_light_01   attack_light_02   attack_light_03   attack_heavy_01
dodge_roll_fwd    hit_react_light   hit_react_heavy    ko_front
```

Quaternius's library won't have these exact names — pick the closest-fitting
source clip for each (a jab/cross/hook-style punch for the three lights, a
big telegraphed swing for heavy, a roll for dodge, stagger animations for
hit-reacts, a fall/collapse for KO) and rename the retargeted result to
match. Reference the frame-timing table in
[`ANIMATION_TREE_SETUP.md`](ANIMATION_TREE_SETUP.md) § 6 for how long each
should be (e.g. `attack_light_01` ≈ 12f windup / 10f active / 18f recovery
at 30fps) — trim/retime the source clip if it's very different in length,
or the phase-timer-driven hit windows in `player_controller.gd` will be out
of sync with what's visually happening.

## Step 5 — Bring the retargeted clips into `mouse.glb`'s AnimationPlayer

Once retargeted and named correctly, they need to live in the same
AnimationPlayer/library that `AnimationTreeBuilder.gd` already searches
(it recursively finds *any* AnimationPlayer under the fighter's `MouseModel`
node — see `_find_anim_player()` in `autoloads/animation_tree_builder.gd`).
The cleanest way: use Godot's **Advanced Import Settings** on `mouse.glb` to
merge the retargeted AnimationLibrary in at import time, so the clips ship
inside `mouse.glb` itself alongside `Mouse_Idle`/`Mouse_Walk`/`Mouse_Run`.

## Step 6 — Clean up and verify

- Delete the temporary `assets/characters/_quaternius_source/` folder once
  the retargeted clips are baked into `mouse.glb` — no need to keep the
  full source pack in the repo.
- Run the arena (F6 on `rumble_arena_back_alley.tscn`) and throw some
  punches — combat should now play real motion instead of the `Mouse_Idle`
  placeholder.
- No code changes needed anywhere — `AnimationTreeBuilder.gd` picks up the
  real clips automatically the moment they exist under these exact names.

## If Godot's native retarget doesn't cleanly handle this rig

If the bone-count/hierarchy mismatch between Quaternius's rig and the mouse
rig turns out to be too different for `BoneMap` to produce clean results
(you'll see this as broken/stretched limbs in the preview), fall back to
manual retargeting in Blender using Rigify or bone constraints — more work,
but gives full manual control over the mapping. The procedural script
(`tools/blender_scripts/generate_combat_animations.py`) remains a fallback
either way if retargeting proves too time-consuming to get right.
