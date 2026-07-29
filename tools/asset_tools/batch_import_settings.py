#!/usr/bin/env python3
"""Print the Godot import settings each arena texture needs.

Despite the filename, this does NOT write any .import files — Godot's
.import format has internal fields (uid, dest_files hashes, etc.) that
aren't safe to hand-author outside the editor. This prints a checklist for
manual configuration via the Import dock instead. If a texture already has
a correct .import file (most do, once configured once), Godot won't lose
those settings — this script is only useful for a first-time setup pass on
newly generated textures.
"""

import os
import json

def create_import_settings():
	"""Create .import metadata files for all arena textures."""
	
	textures_dir = "assets/textures/arena"
	
	# Define import settings per file type
	albedo_settings = {
		"vram_texture/compress/mode": 2,  # VRAM Compressed (ETC2)
		"compress/normal_map": 0,
		"svg/scale": 1.0,
		"importer": "texture",
		"type": "CompressedTexture2D"
	}
	
	normal_settings = {
		"vram_texture/compress/mode": 2,  # VRAM Compressed (ETC2)
		"compress/normal_map": 1,  # Enable normal map
		"importer": "texture",
		"type": "CompressedTexture2D"
	}
	
	roughness_settings = {
		"vram_texture/compress/mode": 2,  # VRAM Compressed (ETC2)
		"compress/normal_map": 0,
		"importer": "texture",
		"type": "CompressedTexture2D"
	}
	
	emission_settings = {
		"vram_texture/compress/mode": 2,  # VRAM Compressed (ETC2)
		"compress/normal_map": 0,
		"importer": "texture",
		"type": "CompressedTexture2D"
	}
	
	# List all files
	for filename in os.listdir(textures_dir):
		filepath = os.path.join(textures_dir, filename)
		
		if filename.endswith("_albedo.webp"):
			settings = albedo_settings
		elif filename.endswith("_normal.png"):
			settings = normal_settings
		elif filename.endswith("_r_m.png"):
			settings = roughness_settings
		elif filename.endswith("_emissive.webp"):
			settings = emission_settings
		else:
			continue
		
		# Create .import file metadata
		import_path = filepath + ".import"
		
		# Note: Godot generates .import files automatically, so we just document what settings are needed
		print(f"Configure {filename}:")
		print(f"  - Compression: VRAM Compressed (ETC2)")
		
		if "_normal" in filename or "_r_m" in filename:
			print(f"  - sRGB: OFF (Linear)")
		else:
			print(f"  - sRGB: ON")
		
		print(f"  - Mipmaps: ON")
		print()

def main():
	print("=" * 60)
	print("Arena Texture Import Configuration")
	print("=" * 60)
	print("\nManual steps in Godot:")
	print("1. Reload Godot (Ctrl+Shift+F5)")
	print("2. For EACH texture, right-click → Import Settings")
	print("3. Apply settings below:\n")
	
	create_import_settings()
	
	print("=" * 60)
	print("After configuring all 16 textures, click 'Reimport'")
	print("=" * 60)

if __name__ == "__main__":
	main()