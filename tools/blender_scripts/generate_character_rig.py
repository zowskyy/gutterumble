"""
generate_character_rig.py
────────────────────────────────────────────────────────────────────────────
Builds a new gang-member skeleton by CLONING Mouse.rig from mouse.glb,
instead of hand-building bones from scratch.

Why: the old version of this script built a 5-bone stick rig (Hips/Spine/
Chest/Neck/Head, no arms or legs). Any mesh skinned to that rig would be
100% incompatible with mouse.glb's actual skeleton (147 bones, MakeHuman
naming: spine01-05, clavicle.L/.R, upperarm01-02.L/.R, wrist.L/.R,
upperleg01-02.L/.R, foot.L/.R, etc.) and with the Quaternius UAL animations
being retargeted onto that skeleton via SkeletonProfileHumanoid — see
assets/characters/mouse/QUATERNIUS_RETARGET_SETUP.md. Every gang-member
model would have needed its own separate retarget pass, by hand, forever.

Cloning Mouse.rig instead means every new character shares the *exact same*
bone names and hierarchy as mouse.glb. Any animation retargeted once onto
Mouse.rig plays back correctly on every character built this way — zero
additional retargeting work per character.

── HOW TO RUN ──────────────────────────────────────────────────────────────
1. Open Blender. File > Import > glTF 2.0 -> assets/characters/mouse/mouse.glb
2. Switch to the "Scripting" workspace tab, open this file, click Run Script.
3. It duplicates "Mouse.rig" as "<name>.rig" with identical bone names/
   hierarchy/rest pose — nothing about the skeleton itself changes.
4. Model or import the new character's mesh (built to roughly the same
   proportions/height as mouse.glb — the skeleton's rest pose won't match a
   wildly different body shape).
5. Parent the new mesh to "<name>.rig" with automatic weights
   (Ctrl+P > With Automatic Weights), or use Weight > Transfer Weights from
   Mouse's mesh as a starting point and hand-correct problem areas (hands,
   face, cloth).
6. Export as glb (Format: glTF Binary, Include > Animation ON) to
   assets/characters/<name>/<name>.glb.
7. Because bone names match mouse.glb exactly, the same SkeletonProfileHumanoid
   BoneMap from QUATERNIUS_RETARGET_SETUP.md applies unchanged — no new
   mapping step in Godot's import dock.

── LIMITATIONS ─────────────────────────────────────────────────────────────
This does NOT model the character for you — concept art -> 3D mesh is still
a manual modeling/sculpting pass (or an external image-to-3D tool of your
choosing). This script only solves the "every character needs a
UAL-compatible skeleton" problem so that step doesn't have to be repeated
per character.
"""

import bpy

SOURCE_RIG_NAME = "Mouse.rig"


def clone_character_rig(new_name: str, source_rig_name: str = SOURCE_RIG_NAME):
	source = bpy.data.objects.get(source_rig_name)
	if source is None or source.type != 'ARMATURE':
		raise RuntimeError(
			f"'{source_rig_name}' not found or not an armature. "
			"Import mouse.glb first (File > Import > glTF 2.0)."
		)

	bpy.ops.object.select_all(action='DESELECT')
	source.select_set(True)
	bpy.context.view_layer.objects.active = source

	bpy.ops.object.duplicate(linked=False)
	clone = bpy.context.active_object
	clone.name = f"{new_name}.rig"
	clone.data.name = f"{new_name}.rig_data"

	# Bone names/hierarchy/rest pose are untouched by duplicate() — that's
	# the whole point. Only the object-level name changes so multiple
	# character rigs can coexist in the same scene without collisions.

	print(f"Cloned '{source_rig_name}' -> '{clone.name}' "
	      f"({len(clone.data.bones)} bones, identical names/hierarchy).")
	print("Next: model/skin the mesh to this armature, matching mouse.glb's "
	      "proportions, then parent with automatic weights.")
	return clone


if __name__ == "__main__":
	clone_character_rig(new_name="GangMember")
