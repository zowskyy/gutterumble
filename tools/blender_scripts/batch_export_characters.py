import bpy
import os

def batch_export_characters(output_dir="assets/models", export_format="glb"):
	os.makedirs(output_dir, exist_ok=True)
	exported = 0
	
	for obj in bpy.data.objects:
		if obj.type == 'ARMATURE':
			bpy.context.view_layer.objects.active = obj
			obj.select_set(True)
			
			output_path = os.path.join(output_dir, f"{obj.name}.glb")
			bpy.ops.export_scene.gltf(
				filepath=output_path,
				check_existing=False,
				export_format='GLB',
				export_image_format='WEBP',
				export_compression_format='DRACO',
			)
			
			print(f"Exported: {obj.name}")
			exported += 1
			
			obj.select_set(False)
	
	print(f"Total exported: {exported} characters")
	return exported

if __name__ == "__main__":
	batch_export_characters()
