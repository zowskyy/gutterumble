#!/usr/bin/env python3
"""Batch convert PNG textures to WebP for Android optimization."""

from PIL import Image
import os
import sys

def convert_png_to_webp(input_dir, output_dir, quality=80):
	"""Convert all PNG files in input_dir to WebP in output_dir."""
	if not os.path.exists(input_dir):
		print(f"Input directory not found: {input_dir}")
		return
	
	os.makedirs(output_dir, exist_ok=True)
	
	for filename in os.listdir(input_dir):
		if filename.endswith(".png"):
			input_path = os.path.join(input_dir, filename)
			output_filename = filename.replace(".png", ".webp")
			output_path = os.path.join(output_dir, output_filename)
			
			try:
				img = Image.open(input_path)
				img.save(output_path, "WEBP", quality=quality)
				print(f"Converted {filename} -> {output_filename}")
			except Exception as e:
				print(f"Failed to convert {filename}: {e}")

if __name__ == "__main__":
	input_dir = "assets/textures/generated"
	output_dir = "assets/textures/webp"
	convert_png_to_webp(input_dir, output_dir, quality=85)
	print("Batch conversion complete!")
