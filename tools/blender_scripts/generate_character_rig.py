import bpy
from mathutils import Vector

def create_character_rig(name="Character", height=1.8):
	bpy.ops.object.select_all(action='SELECT')
	bpy.ops.object.delete(use_global=False)
	
	bpy.ops.object.armature_add(name=name)
	armature = bpy.context.active_object
	armature.data.display_type = 'STICK'
	
	bpy.context.view_layer.objects.active = armature
	bpy.ops.object.mode_set(mode='EDIT')
	
	bones_data = [
		("Hips", (0, 0, 0), (0, 0.1, 0), None),
		("Spine", (0, 0.1, 0), (0, 0.5, 0), "Hips"),
		("Chest", (0, 0.5, 0), (0, 0.9, 0), "Spine"),
		("Neck", (0, 0.9, 0), (0, 1.4, 0), "Chest"),
		("Head", (0, 1.4, 0), (0, 1.8, 0), "Neck"),
	]
	
	edit_bones = armature.data.edit_bones
	bone_objects = {}
	
	for name, head, tail, parent in bones_data:
		bone = edit_bones.new(name)
		bone.head = Vector(head)
		bone.tail = Vector(tail)
		bone_objects[name] = bone
		
		if parent and parent in bone_objects:
			bone.parent = bone_objects[parent]
	
	bpy.ops.object.mode_set(mode='OBJECT')
	
	bpy.ops.mesh.primitive_uv_sphere_add(radius=0.35, location=(0, 0.9, 0))
	body = bpy.context.active_object
	body.name = "CharacterBody"
	body.scale = (1, 1.8, 1)
	
	body.parent = armature
	
	modifier = body.modifiers.new(name="Armature", type='ARMATURE')
	modifier.object = armature
	
	print(f"Created character rig: {name}")
	return armature, body

if __name__ == "__main__":
	create_character_rig(name="GangMember")
