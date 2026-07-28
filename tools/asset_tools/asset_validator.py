#!/usr/bin/env python3
"""Validate asset structure and sizes for Android build."""

import os
import json

def validate_assets():
	print("Validating GUTTERUMBLE assets...")
	
	required_dirs = [
		"assets/textures/generated",
		"assets/models",
		"assets/props/weapons",
		"assets/shaders",
	]
	
	for dir_path in required_dirs:
		if os.path.exists(dir_path):
			file_count = len(os.listdir(dir_path))
			print(f"✓ {dir_path} ({file_count} files)")
		else:
			print(f"✗ {dir_path} (missing)")
	
	# Check texture sizes
	max_size = 2048
	for root, dirs, files in os.walk("assets/textures"):
		for file in files:
			if file.endswith((".png", ".webp")):
				path = os.path.join(root, file)
				size_mb = os.path.getsize(path) / (1024 * 1024)
				if size_mb > 5:
					print(f"⚠ {file} is {size_mb:.2f}MB (compress for Android)")
	
	print("Validation complete!")

if __name__ == "__main__":
	validate_assets()
