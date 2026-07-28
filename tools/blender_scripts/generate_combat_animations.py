"""
generate_combat_animations.py
────────────────────────────────────────────────────────────────────────────
Procedurally keyframes all 8 missing combat clips directly on the Mouse.rig
armature, using the exact bone names found in mouse.glb and the exact frame
timing already specified in assets/characters/mouse/ANIMATION_TREE_SETUP.md.

This is NOT hand-animated — it's arc-based procedural motion (windup pull-back
-> active swing -> recovery settle). It will look mechanical, but the TIMING
is game-correct, so combat will read properly the moment you import it. Treat
these as placeholder clips you can refine later, or ship as-is for an MVP.

── HOW TO RUN ──────────────────────────────────────────────────────────────
1. Open Blender (4.x recommended — matches Godot 4's glTF exporter expectations).
2. File > Import > glTF 2.0  ->  select assets/characters/mouse/mouse.glb
3. Switch to the "Scripting" workspace tab.
4. Open this file (or paste its contents) into a new text block.
5. Click "Run Script" (the ▶ button). Watch the System Console for progress.
6. Select the armature "Mouse.rig" in the Outliner if not already selected.
7. File > Export > glTF 2.0
     - Format: glTF Binary (.glb)
     - Include > Animation: ON, "Limit to Playback Range": OFF
     - Overwrite: assets/characters/mouse/mouse.glb
     (Back up the original first if you want to keep the source-only version.)
8. Back in Godot: FileSystem panel -> right-click mouse.glb -> Reimport.
9. Open AnimationTreeBuilder.gd (autoloads/) and swap the placeholder clip
   names in the combat_states loop — they already match these action names
   1:1 (attack_light_01, attack_light_02, ... ko_front) so if you ran this
   script with default names, NO CODE CHANGES ARE NEEDED. Godot will just
   start playing the real clips instead of Mouse_Idle.

── BONE MAP (from mouse.glb, MakeHuman/Rigify-style naming) ────────────────
Root:            root
Spine:           spine01..spine05, neck01..neck03, head
Right arm:       clavicle.R, shoulder01.R, upperarm01.R, upperarm02.R,
                 lowerarm01.R, lowerarm02.R, wrist.R
Left arm:        (same with .L)
Legs:            pelvis.L/.R, upperleg01/02.L/.R, lowerleg01/02.L/.R, foot.L/.R

If your punches look like they bend the wrong direction, flip the sign on
ARM_SWING_DEG below — bone roll/orientation varies per rig export.
"""

import bpy
import math

FPS = 30.0  # matches animation/fps=30 in mouse.glb.import

# ── Tunables — flip sign here if punches look inverted in your rig ─────────
ARM_SWING_DEG = 65.0
HIP_TWIST_DEG = 12.0
DODGE_DIST_M  = 2.2
KO_FALL_DEG   = 88.0


def get_armature() -> bpy.types.Object:
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            return obj
    raise RuntimeError("No armature found in scene — import mouse.glb first.")


def ensure_action(armature: bpy.types.Object, name: str) -> bpy.types.Action:
    action = bpy.data.actions.get(name)
    if action is None:
        action = bpy.data.actions.new(name=name)
    action.use_fake_user = True
    if armature.animation_data is None:
        armature.animation_data_create()
    armature.animation_data.action = action
    return action


def set_rest_mode(armature: bpy.types.Object) -> None:
    for pb in armature.pose.bones:
        pb.rotation_mode = "XYZ"


def kf_rot(armature: bpy.types.Object, bone: str, frame: int, deg_xyz) -> None:
    pb = armature.pose.bones.get(bone)
    if pb is None:
        return
    pb.rotation_euler = (
        math.radians(deg_xyz[0]),
        math.radians(deg_xyz[1]),
        math.radians(deg_xyz[2]),
    )
    pb.keyframe_insert(data_path="rotation_euler", frame=frame)


def kf_root_loc(armature: bpy.types.Object, frame: int, loc_xyz) -> None:
    pb = armature.pose.bones.get("root")
    if pb is None:
        return
    pb.location = loc_xyz
    pb.keyframe_insert(data_path="location", frame=frame)


def reset_pose(armature: bpy.types.Object) -> None:
    for pb in armature.pose.bones:
        pb.rotation_euler = (0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)


def clip_punch(armature, name: str, side: str, windup_f: int, active_f: int,
               recovery_f: int, swing_deg: float) -> None:
    """Generic punch arc: idle -> windup pull-back -> active swing -> recovery."""
    ensure_action(armature, name)
    reset_pose(armature)
    arm_up = f"upperarm01.{side}"
    arm_lo = f"lowerarm01.{side}"
    spine  = "spine03"

    f0 = 0
    f1 = windup_f
    f2 = windup_f + active_f
    f3 = windup_f + active_f + recovery_f

    kf_rot(armature, arm_up, f0, (0, 0, 0))
    kf_rot(armature, arm_lo, f0, (0, 0, 0))
    kf_rot(armature, spine,  f0, (0, 0, 0))

    # Windup — pull back and coil the spine
    kf_rot(armature, arm_up, f1, (-swing_deg * 0.5, 0, -10 if side == "R" else 10))
    kf_rot(armature, arm_lo, f1, (-20, 0, 0))
    kf_rot(armature, spine,  f1, (0, 0, -HIP_TWIST_DEG if side == "R" else HIP_TWIST_DEG))

    # Active — snap forward through the target
    kf_rot(armature, arm_up, f2, (swing_deg, 0, 5 if side == "R" else -5))
    kf_rot(armature, arm_lo, f2, (10, 0, 0))
    kf_rot(armature, spine,  f2, (0, 0, HIP_TWIST_DEG if side == "R" else -HIP_TWIST_DEG))

    # Recovery — settle back to neutral
    kf_rot(armature, arm_up, f3, (0, 0, 0))
    kf_rot(armature, arm_lo, f3, (0, 0, 0))
    kf_rot(armature, spine,  f3, (0, 0, 0))

    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f3)


def clip_haymaker(armature, name: str, windup_f: int, active_f: int, recovery_f: int) -> None:
    """Wide telegraphed heavy swing — both arms involved, big spine wind-up."""
    ensure_action(armature, name)
    reset_pose(armature)
    f0, f1 = 0, windup_f
    f2 = windup_f + active_f
    f3 = windup_f + active_f + recovery_f

    kf_rot(armature, "upperarm01.R", f0, (0, 0, 0))
    kf_rot(armature, "spine03",      f0, (0, 0, 0))

    # Big windup — arm cocks far back, torso rotates away
    kf_rot(armature, "upperarm01.R", f1, (-40, -60, -20))
    kf_rot(armature, "lowerarm01.R", f1, (-30, 0, 0))
    kf_rot(armature, "spine03",      f1, (0, 0, -25))
    kf_rot(armature, "spine01",      f1, (0, 0, -10))

    # Active — huge arc through
    kf_rot(armature, "upperarm01.R", f2, (110, 40, 10))
    kf_rot(armature, "lowerarm01.R", f2, (10, 0, 0))
    kf_rot(armature, "spine03",      f2, (0, 0, 30))
    kf_rot(armature, "spine01",      f2, (0, 0, 12))

    # Recovery — overextended, slow return
    kf_rot(armature, "upperarm01.R", f3, (0, 0, 0))
    kf_rot(armature, "lowerarm01.R", f3, (0, 0, 0))
    kf_rot(armature, "spine03",      f3, (0, 0, 0))
    kf_rot(armature, "spine01",      f3, (0, 0, 0))

    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f3)


def clip_dodge(armature, name: str, total_f: int) -> None:
    """Forward roll — root translates forward, spine tucks and untucks."""
    ensure_action(armature, name)
    reset_pose(armature)
    f0, fmid, f1 = 0, total_f // 2, total_f

    kf_root_loc(armature, f0, (0, 0, 0))
    kf_rot(armature, "spine03", f0, (0, 0, 0))

    kf_root_loc(armature, fmid, (0, 0.2, -DODGE_DIST_M * 0.5))
    kf_rot(armature, "spine03", fmid, (45, 0, 0))     # tuck forward mid-roll
    kf_rot(armature, "spine01", fmid, (30, 0, 0))

    kf_root_loc(armature, f1, (0, 0, -DODGE_DIST_M))
    kf_rot(armature, "spine03", f1, (0, 0, 0))
    kf_rot(armature, "spine01", f1, (0, 0, 0))

    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f1)


def clip_hit_react(armature, name: str, total_f: int, heavy: bool) -> None:
    """Snap back from impact, settle to idle."""
    ensure_action(armature, name)
    reset_pose(armature)
    f0 = 0
    f1 = int(total_f * 0.3)
    f2 = total_f
    snap = -22 if heavy else -12

    kf_rot(armature, "spine03", f0, (0, 0, 0))
    kf_rot(armature, "neck01",  f0, (0, 0, 0))

    kf_rot(armature, "spine03", f1, (snap, 0, 0))
    kf_rot(armature, "neck01",  f1, (snap * 0.6, 0, 0))

    kf_rot(armature, "spine03", f2, (0, 0, 0))
    kf_rot(armature, "neck01",  f2, (0, 0, 0))

    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f2)


def clip_ko(armature, name: str, total_f: int) -> None:
    """Fall backward and down — no loop, holds on the ground pose."""
    ensure_action(armature, name)
    reset_pose(armature)
    f0 = 0
    f1 = int(total_f * 0.35)
    f2 = total_f

    kf_rot(armature, "spine03", f0, (0, 0, 0))
    kf_root_loc(armature, f0, (0, 0, 0))

    kf_rot(armature, "spine03", f1, (-KO_FALL_DEG * 0.5, 0, 8))
    kf_root_loc(armature, f1, (0, -0.3, 0.2))

    kf_rot(armature, "spine03", f2, (-KO_FALL_DEG, 0, 15))
    kf_root_loc(armature, f2, (0, -0.9, 0.5))

    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f2)


def main() -> None:
    armature = get_armature()
    set_rest_mode(armature)

    # Frame counts taken directly from ANIMATION_TREE_SETUP.md § 6
    clip_punch(armature, "attack_light_01", "R", 12, 10, 18, ARM_SWING_DEG)
    clip_punch(armature, "attack_light_02", "L", 10, 10, 20, ARM_SWING_DEG * 1.1)
    clip_punch(armature, "attack_light_03", "R", 16, 12, 30, ARM_SWING_DEG * 1.3)
    clip_haymaker(armature, "attack_heavy_01", 28, 14, 42)
    clip_dodge(armature, "dodge_roll_fwd", 35)
    clip_hit_react(armature, "hit_react_light", 20, heavy=False)
    clip_hit_react(armature, "hit_react_heavy", 30, heavy=True)
    clip_ko(armature, "ko_front", 60)

    reset_pose(armature)
    print("[generate_combat_animations] Done — 8 actions created:")
    for n in ["attack_light_01", "attack_light_02", "attack_light_03",
              "attack_heavy_01", "dodge_roll_fwd", "hit_react_light",
              "hit_react_heavy", "ko_front"]:
        print("  -", n)
    print("[generate_combat_animations] Now: select armature -> "
          "File > Export > glTF 2.0 -> overwrite mouse.glb with Animation ON.")


if __name__ == "__main__":
    main()
