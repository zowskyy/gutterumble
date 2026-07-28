import bpy

def create_lod_variants(source_object, name="Model"):
	lods = []
	
	bpy.ops.object.select_all(action='SELECT')
	source_object.select_set(True)
	bpy.context.view_layer.objects.active = source_object
	
	mod = source_object.modifiers.new(name="Decimate", type='DECIMATE')
	mod.ratio = 0.5
	
	lod1_copy = source_object.copy()
	lod1_copy.data = source_object.data.copy()
	lod1_copy.name = "LOD1_Medium"
	lods.append((lod1_copy, "LOD1_Medium"))
	
	mod.ratio = 0.25
	lod2_copy = source_object.copy()
	lod2_copy.data = source_object.data.copy()
	lod2_copy.name = "LOD2_Low"
	lods.append((lod2_copy, "LOD2_Low"))
	
	print(f"Created 3 LOD variants for {name}")
	return lods

if __name__ == "__main__":
	create_lod_variants(bpy.context.active_object)
