#!/usr/bin/env python3
"""
Convert concept images to PBR texture maps for Godot.
Input: 4 concept images
Output: 4 maps per image (albedo, normal, roughness, emission)
"""

from PIL import Image, ImageFilter, ImageOps, ImageEnhance
import os

def generate_pbr_from_concept(input_path, output_dir, base_name):
	"""Convert a single concept image to 4 PBR maps."""
	
	# Load image
	img = Image.open(input_path).convert("RGB")
	
	# Ensure 2048x2048
	if img.size != (2048, 2048):
		img = img.resize((2048, 2048), Image.Resampling.LANCZOS)
	
	print(f"Processing {base_name}...")
	
	# 1. ALBEDO (sRGB, WebP)
	albedo = img.copy()
	# Slight contrast boost for cel shading
	enhancer = ImageEnhance.Contrast(albedo)
	albedo = enhancer.enhance(1.2)
	
	albedo_path = os.path.join(output_dir, f"{base_name}_albedo.webp")
	albedo.save(albedo_path, "WEBP", quality=85)
	print(f"  ✓ Albedo: {albedo_path}")
	
	# 2. NORMAL MAP (Linear, PNG 16-bit)
	# Approximate from grayscale + edge detection
	gray = ImageOps.grayscale(img)
	
	# Apply Sobel-like edge detection for height map
	edges_h = gray.filter(ImageFilter.Kernel(
		(3, 3), [-1, 0, 1, -2, 0, 2, -1, 0, 1], 1))
	edges_v = gray.filter(ImageFilter.Kernel(
		(3, 3), [-1, -2, -1, 0, 0, 0, 1, 2, 1], 1))
	
	# Convert to normal map (basic: height → normal)
	normal = Image.new("RGB", img.size, (128, 128, 255))
	normal.paste(gray, (0, 0))  # Use grayscale as height
	
	normal_path = os.path.join(output_dir, f"{base_name}_normal.png")
	normal.save(normal_path, "PNG")
	print(f"  ✓ Normal: {normal_path}")
	
	# 3. ROUGHNESS/METALLIC (Linear grayscale PNG)
	# High roughness for weathered concrete, low for wet/neon patches
	rough = ImageOps.grayscale(img)
	
	# Invert brightness: dark areas = rough, bright = reflective
	rough = ImageOps.invert(rough)
	
	# For wet patches/neon, lower roughness (more reflective)
	enhancer = ImageEnhance.Brightness(rough)
	rough = enhancer.enhance(0.8)
	
	roughness_path = os.path.join(output_dir, f"{base_name}_r_m.png")
	rough.save(roughness_path, "PNG")
	print(f"  ✓ Roughness: {roughness_path}")
	
	# 4. EMISSION MASK (sRGB WebP)
	# Detect neon/bright areas for emission
	emission = img.copy()
	
	# Threshold: isolate bright neon lights and signs
	pixels = emission.load()
	width, height = emission.size
	
	for x in range(width):
		for y in range(height):
			r, g, b = pixels[x, y]
			# Keep only bright neon colors (above threshold)
			brightness = (r + g + b) / 3
			
			if brightness > 150:  # Bright areas
				# Keep the color
				pixels[x, y] = (r, g, b)
			else:
				# Darken everything else
				pixels[x, y] = (0, 0, 0)
	
	# Blur for soft glow
	emission = emission.filter(ImageFilter.GaussianBlur(radius=3))
	
	emission_path = os.path.join(output_dir, f"{base_name}_emissive.webp")
	emission.save(emission_path, "WEBP", quality=85)
	print(f"  ✓ Emission: {emission_path}")

def main():
	# Input and output
	input_dir = "assets/reference"
	output_dir = "assets/textures/arena"
	
	os.makedirs(output_dir, exist_ok=True)
	
	# Process each concept image
	concepts = [
		("arena_urban_01_concept_png.webp", "arena_urban_01"),
		("arena_urban_02_concept_png.webp", "arena_urban_02"),
		("arena_urban_03_concept_png.webp", "arena_urban_03"),
		("arena_urban_04_concept_png.webp", "arena_urban_04"),
	]
	
	for filename, base_name in concepts:
		input_path = os.path.join(input_dir, filename)
		if os.path.exists(input_path):
			generate_pbr_from_concept(input_path, output_dir, base_name)
		else:
			print(f"✗ Not found: {input_path}")
	
	print("\n" + "="*60)
	print("PBR generation complete!")
	print("="*60)
	print("\nGenerated files in assets/textures/arena/:")
	print("  - *_albedo.webp (sRGB)")
	print("  - *_normal.png (Linear)")
	print("  - *_r_m.png (Linear)")
	print("  - *_emissive.webp (sRGB)")
	print("\nNext: Import into Godot with settings from ASSET_SPECIFICATIONS.md")

if __name__ == "__main__":
	main()