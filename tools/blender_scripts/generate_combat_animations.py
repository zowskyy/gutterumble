"""
generate_combat_animations.py
────────────────────────────────────────────────────────────────────────────
Procedurally keyframes all 8 missing combat clips directly on the Mouse.rig
armature, using the exact bone names found in mouse.glb and the exact frame
timing already specified in assets/characters/mouse/ANIMATION_TREE_SETUP.md.

v2 — reworked for motion quality, not just correct timing. The first version
only hit windup/active/recovery poses with linear interpolation and arms
moving in isolation — mechanically correct but visibly robotic (no weight
transfer, no follow-through, no easing). This version applies the animation
principles that actually read as "human":
  - Anticipation: a small counter-lean before the main windup, not just the
    windup itself — real bodies telegraph a beat before committing.
  - Weight shift: hips (spine01) and a rear-leg knee-bend counter-rotate
    against the shoulders (spine03) instead of the whole torso moving as one
    rigid block — hip-leads-shoulders separation is what makes a punch read
    as power coming from the ground, not just an arm swinging.
  - Follow-through / overshoot: the arm continues slightly PAST the contact
    pose before recoiling back to neutral, instead of snapping directly to
    rest — bodies don't stop instantly.
  - Secondary motion: head/neck keyed a few frames behind the spine, not at
    the identical frame — creates natural lag/overlap instead of everything
    moving in lockstep.
  - Bezier easing (not linear) on every keyframe — real motion accelerates
    into and decelerates out of a pose; linear interpolation is the single
    biggest tell of "computer generated" motion.

None of this makes these clips indistinguishable from hand-keyed animation —
that's a genuinely different skill and effort level, and procedural arcs
have a ceiling. What this DOES do is remove the specific robotic tells
(linear timing, isolated limb motion, no follow-through) that make
procedural motion read as obviously fake, while staying inside what a
script can reliably produce without visual iteration in the Blender viewport.

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
9. AnimationTreeBuilder.gd already routes combat states to these exact clip
   names — no code changes needed. Godot starts playing the real clips
   instead of the Mouse_Idle placeholder immediately on reimport.

── STRONGLY RECOMMENDED — this is still procedural, not hand-animated ───────
Play each clip in Blender's Dope Sheet / viewport BEFORE exporting and:
  - Flip ARM_SWING_DEG's sign if punches bend the wrong way (rig-dependent).
  - Nudge the *_DEG tunables below if the weight shift looks exaggerated or
    too subtle for this character's proportions.
  - If you have any animation skill at all, use these as a base layer and
    add hand-keyed detail on top (knuckle curl, shoulder blade motion,
    finger poses) — procedural arcs get you 70% of the way, not 100%.

── BONE MAP (from mouse.glb, MakeHuman/Rigify-style naming) ────────────────
Root:            root
Spine:           spine01..spine05, neck01..neck03, head
Right arm:       clavicle.R, shoulder01.R, upperarm01.R, upperarm02.R,
                 lowerarm01.R, lowerarm02.R, wrist.R
Left arm:        (same with .L)
Legs:            pelvis.L/.R, upperleg01/02.L/.R, lowerleg01/02.L/.R, foot.L/.R
"""

import bpy
import math

FPS = 30.0  # matches animation/fps=30 in mouse.glb.import

# ── Tunables — flip sign here if punches look inverted in your rig ─────────
ARM_SWING_DEG      = 65.0
HIP_TWIST_DEG      = 12.0     # shoulder (spine03) rotation
HIP_LEAD_DEG       = 6.0      # hip (spine01) counter-rotation — hips lead, shoulders follow
LEG_DRIVE_DEG      = 10.0     # rear-leg knee-bend during weight transfer
ANTICIPATION_DEG   = 8.0      # small counter-lean before the main windup
OVERSHOOT_MULT     = 1.12     # follow-through extends this far past the active pose
DODGE_DIST_M       = 2.2
KO_FALL_DEG        = 88.0
NECK_LAG_FRAMES    = 2        # head/neck keyed this many frames behind the spine


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


def apply_easing(armature: bpy.types.Object) -> None:
    """Bezier + ease-in-out on every keyframe of the CURRENT action.
    Call this at the end of each clip_* function, after all inserts for
    that action are done (armature.animation_data.action must still point
    at the clip being finished). Linear interpolation — Blender's default
    for keyframe_insert() — is the single biggest tell of procedural
    motion; real bodies accelerate into and decelerate out of every pose.
    """
    action = armature.animation_data.action
    if action is None:
        return
    for fcurve in action.fcurves:
        for kp in fcurve.keyframe_points:
            kp.interpolation = "BEZIER"
            kp.easing = "EASE_IN_OUT"
        fcurve.update()


def clip_punch(armature, name: str, side: str, windup_f: int, active_f: int,
               recovery_f: int, swing_deg: float) -> None:
    """Punch arc with weight transfer: idle -> anticipation -> windup (hip
    leads, shoulder coils) -> active (contact) -> overshoot (follow-through)
    -> recovery (settle). Rear leg drives the weight shift; head lags the
    spine by a couple frames for secondary motion.
    """
    ensure_action(armature, name)
    reset_pose(armature)
    arm_up   = f"upperarm01.{side}"
    arm_lo   = f"lowerarm01.{side}"
    shoulder = "spine03"
    hip      = "spine01"
    rear_leg = f"upperleg01.{'L' if side == 'R' else 'R'}"   # opposite leg drives forward
    sign     = -1 if side == "R" else 1

    f_idle       = 0
    f_anticipate = max(1, int(windup_f * 0.35))
    f_windup     = windup_f
    f_active     = windup_f + active_f
    f_overshoot  = f_active + max(1, int(active_f * 0.4))
    f_recovery   = windup_f + active_f + recovery_f

    # Idle
    kf_rot(armature, arm_up, f_idle, (0, 0, 0))
    kf_rot(armature, arm_lo, f_idle, (0, 0, 0))
    kf_rot(armature, shoulder, f_idle, (0, 0, 0))
    kf_rot(armature, hip, f_idle, (0, 0, 0))
    kf_rot(armature, rear_leg, f_idle, (0, 0, 0))

    # Anticipation — tiny counter-lean the wrong way before committing
    kf_rot(armature, arm_up, f_anticipate, (10 * sign * -1, 0, 0))
    kf_rot(armature, shoulder, f_anticipate, (0, 0, ANTICIPATION_DEG * sign * -1))
    kf_rot(armature, hip, f_anticipate, (0, 0, ANTICIPATION_DEG * 0.5 * sign))

    # Windup — hip leads (rotates first/further), shoulder coils, rear leg bends
    kf_rot(armature, arm_up, f_windup, (-swing_deg * 0.5, 0, -10 * sign))
    kf_rot(armature, arm_lo, f_windup, (-20, 0, 0))
    kf_rot(armature, shoulder, f_windup, (0, 0, -HIP_TWIST_DEG * sign))
    kf_rot(armature, hip, f_windup, (0, 0, -HIP_LEAD_DEG * sign))
    kf_rot(armature, rear_leg, f_windup, (LEG_DRIVE_DEG, 0, 0))

    # Active — contact. Hip has already started returning (power transferred
    # up the chain), shoulder/arm are at peak extension.
    kf_rot(armature, arm_up, f_active, (swing_deg, 0, 5 * -sign))
    kf_rot(armature, arm_lo, f_active, (10, 0, 0))
    kf_rot(armature, shoulder, f_active, (0, 0, HIP_TWIST_DEG * sign))
    kf_rot(armature, hip, f_active, (0, 0, HIP_LEAD_DEG * 0.4 * sign))
    kf_rot(armature, rear_leg, f_active, (LEG_DRIVE_DEG * 0.3, 0, 0))

    # Overshoot — follow-through past the contact pose before recoiling
    kf_rot(armature, arm_up, f_overshoot, (swing_deg * OVERSHOOT_MULT, 0, 8 * -sign))
    kf_rot(armature, arm_lo, f_overshoot, (18, 0, 0))
    kf_rot(armature, shoulder, f_overshoot, (0, 0, HIP_TWIST_DEG * 1.1 * sign))

    # Recovery — settle back to neutral
    kf_rot(armature, arm_up, f_recovery, (0, 0, 0))
    kf_rot(armature, arm_lo, f_recovery, (0, 0, 0))
    kf_rot(armature, shoulder, f_recovery, (0, 0, 0))
    kf_rot(armature, hip, f_recovery, (0, 0, 0))
    kf_rot(armature, rear_leg, f_recovery, (0, 0, 0))

    # Secondary motion — head/neck lag the shoulder by a couple frames
    _kf_neck_lag(armature, [
        (f_idle, (0, 0, 0)),
        (f_windup, (5 * -sign, 0, -HIP_TWIST_DEG * 0.4 * sign)),
        (f_active, (2 * sign, 0, HIP_TWIST_DEG * 0.4 * sign)),
        (f_recovery, (0, 0, 0)),
    ])

    # +NECK_LAG_FRAMES: the last neck keyframe lands that far past f_recovery
    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f_recovery + NECK_LAG_FRAMES)
    apply_easing(armature)


def clip_haymaker(armature, name: str, windup_f: int, active_f: int, recovery_f: int) -> None:
    """Wide telegraphed heavy swing — big hip/shoulder separation, full-body
    weight transfer, pronounced follow-through. This is the "big" attack so
    the anticipation and overshoot are exaggerated relative to light punches.
    """
    ensure_action(armature, name)
    reset_pose(armature)
    f_idle       = 0
    f_anticipate = max(1, int(windup_f * 0.3))
    f_windup     = windup_f
    f_active     = windup_f + active_f
    f_overshoot  = f_active + max(1, int(active_f * 0.5))
    f_recovery   = windup_f + active_f + recovery_f

    kf_rot(armature, "upperarm01.R", f_idle, (0, 0, 0))
    kf_rot(armature, "spine03", f_idle, (0, 0, 0))
    kf_rot(armature, "spine01", f_idle, (0, 0, 0))
    kf_rot(armature, "upperleg01.L", f_idle, (0, 0, 0))

    # Anticipation — weight rocks back before the big commit
    kf_rot(armature, "upperarm01.R", f_anticipate, (10, -15, 0))
    kf_rot(armature, "spine03", f_anticipate, (0, 0, 12))
    kf_rot(armature, "spine01", f_anticipate, (0, 0, 5))

    # Big windup — arm cocks far back, hips lead the shoulder rotation,
    # rear (left) leg loads weight
    kf_rot(armature, "upperarm01.R", f_windup, (-40, -60, -20))
    kf_rot(armature, "lowerarm01.R", f_windup, (-30, 0, 0))
    kf_rot(armature, "spine03", f_windup, (0, 0, -25))
    kf_rot(armature, "spine01", f_windup, (0, 0, -14))
    kf_rot(armature, "upperleg01.L", f_windup, (16, 0, 0))

    # Active — huge arc through, hip already unwinding ahead of the shoulder
    kf_rot(armature, "upperarm01.R", f_active, (110, 40, 10))
    kf_rot(armature, "lowerarm01.R", f_active, (10, 0, 0))
    kf_rot(armature, "spine03", f_active, (0, 0, 30))
    kf_rot(armature, "spine01", f_active, (0, 0, 8))
    kf_rot(armature, "upperleg01.L", f_active, (4, 0, 0))

    # Overshoot — the punch keeps traveling before it can be reeled back in
    kf_rot(armature, "upperarm01.R", f_overshoot, (124, 46, 14))
    kf_rot(armature, "spine03", f_overshoot, (0, 0, 34))

    # Recovery — overextended, slow return
    kf_rot(armature, "upperarm01.R", f_recovery, (0, 0, 0))
    kf_rot(armature, "lowerarm01.R", f_recovery, (0, 0, 0))
    kf_rot(armature, "spine03", f_recovery, (0, 0, 0))
    kf_rot(armature, "spine01", f_recovery, (0, 0, 0))
    kf_rot(armature, "upperleg01.L", f_recovery, (0, 0, 0))

    _kf_neck_lag(armature, [
        (f_idle, (0, 0, 0)),
        (f_windup, (-8, 0, -10)),
        (f_active, (6, 0, 14)),
        (f_recovery, (0, 0, 0)),
    ])

    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f_recovery + NECK_LAG_FRAMES)
    apply_easing(armature)


def clip_dodge(armature, name: str, total_f: int) -> None:
    """Forward roll — root translates forward, spine tucks and untucks with
    a slight overshoot on the recovery so the roll reads as having momentum
    rather than stopping dead.
    """
    ensure_action(armature, name)
    reset_pose(armature)
    f0, fmid, f_over, f1 = 0, total_f // 2, int(total_f * 0.85), total_f

    kf_root_loc(armature, f0, (0, 0, 0))
    kf_rot(armature, "spine03", f0, (0, 0, 0))

    kf_root_loc(armature, fmid, (0, 0.2, -DODGE_DIST_M * 0.5))
    kf_rot(armature, "spine03", fmid, (45, 0, 0))     # tuck forward mid-roll
    kf_rot(armature, "spine01", fmid, (30, 0, 0))

    # Slight overshoot past the final distance before settling — a body
    # rolling out of a tuck has momentum, it doesn't just stop.
    kf_root_loc(armature, f_over, (0, -0.05, -DODGE_DIST_M * 1.05))
    kf_rot(armature, "spine03", f_over, (-8, 0, 0))

    kf_root_loc(armature, f1, (0, 0, -DODGE_DIST_M))
    kf_rot(armature, "spine03", f1, (0, 0, 0))
    kf_rot(armature, "spine01", f1, (0, 0, 0))

    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f1)
    apply_easing(armature)


def clip_hit_react(armature, name: str, total_f: int, heavy: bool) -> None:
    """Snap back from impact with a small overshoot-and-settle rather than
    a single symmetric snap-back — getting hit knocks you past your
    recovery point slightly before you catch your balance.
    """
    ensure_action(armature, name)
    reset_pose(armature)
    f0 = 0
    f_impact = int(total_f * 0.25)
    f_settle = int(total_f * 0.6)
    f1 = total_f
    snap = -22 if heavy else -12

    kf_rot(armature, "spine03", f0, (0, 0, 0))
    kf_rot(armature, "spine01", f0, (0, 0, 0))

    # Impact — snap back
    kf_rot(armature, "spine03", f_impact, (snap, 0, 0))
    kf_rot(armature, "spine01", f_impact, (snap * 0.3, 0, 0))

    # Settle — a slight overshoot forward before coming to rest (catching
    # balance), not a mirror-image return
    kf_rot(armature, "spine03", f_settle, (snap * 0.3, 0, 0))

    kf_rot(armature, "spine03", f1, (0, 0, 0))
    kf_rot(armature, "spine01", f1, (0, 0, 0))

    # neck01's ONLY keyframes come from _kf_neck_lag below — keying it here
    # too would double-key the bone (harmless where values happen to match,
    # e.g. both landing on (0,0,0) at rest, but redundant and confusing to
    # read in the Dope Sheet, and it defeats the purpose of the lag offset).
    _kf_neck_lag(armature, [
        (f0, (0, 0, 0)),
        (f_impact, (snap * 0.6, 0, 0)),
        (f_settle, (snap * 0.2, 0, 0)),
        (f1, (0, 0, 0)),
    ])

    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f1)
    apply_easing(armature)


def clip_ko(armature, name: str, total_f: int) -> None:
    """Fall backward and down — no loop, holds on the ground pose. A real
    fall has a brief airborne/off-balance beat before gravity fully takes
    over, not a constant-speed collapse.
    """
    ensure_action(armature, name)
    reset_pose(armature)
    f0 = 0
    f_stagger = int(total_f * 0.2)
    f_falling = int(total_f * 0.55)
    f2 = total_f

    kf_rot(armature, "spine03", f0, (0, 0, 0))
    kf_root_loc(armature, f0, (0, 0, 0))

    # Stagger — off-balance beat before the fall really commits
    kf_rot(armature, "spine03", f_stagger, (-KO_FALL_DEG * 0.15, 0, 3))
    kf_root_loc(armature, f_stagger, (0, -0.05, 0.03))

    kf_rot(armature, "spine03", f_falling, (-KO_FALL_DEG * 0.6, 0, 10))
    kf_root_loc(armature, f_falling, (0, -0.45, 0.25))

    kf_rot(armature, "spine03", f2, (-KO_FALL_DEG, 0, 15))
    kf_root_loc(armature, f2, (0, -0.9, 0.5))

    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, f2)
    apply_easing(armature)


def _kf_neck_lag(armature, keyed_poses) -> None:
    """Keys neck01 a few frames behind the given (frame, deg_xyz) list —
    secondary motion / overlapping action, so the head doesn't move in
    perfect lockstep with the spine.
    """
    for frame, deg_xyz in keyed_poses:
        kf_rot(armature, "neck01", frame + NECK_LAG_FRAMES, deg_xyz)


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
    print("[generate_combat_animations] Recommended: scrub through each clip "
          "in the Dope Sheet first — flip ARM_SWING_DEG's sign if punches "
          "bend the wrong way, this is rig-orientation-dependent.")


if __name__ == "__main__":
    main()
