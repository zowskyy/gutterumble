#!/usr/bin/env python3
"""
Convert concept images to PBR texture maps for Godot.
Input: 4 concept images
Output: 4 maps per image (albedo, normal, roughness, emission)

v2 — fixed a real bug in the normal map generation. The previous version
computed Sobel horizontal/vertical edge detection (edges_h, edges_v) and
then never used either result — it pasted the raw grayscale image directly
onto all three RGB channels instead. That produces a file that LOOKS like a
normal map (a grayish PNG) but every pixel has R==G==B, which is not
surface-direction data at all — a real normal map needs R/G to encode
X/Y surface tilt (centered at 128 = "flat") and B to encode the up-facing Z
component (typically high, ~200-255). Verified this was live and in use:
sampled arena_urban_01_normal.png's actual pixel data before fixing this —
every sampled pixel had R==G==B, confirming the bug was shipping in
committed assets and feeding real-time lighting math in cel_shaded.gdshader
(`vec3 normal = ...texture(normal_texture, UV)...; dot(normal, light_dir)`).

This version computes an actual height-to-normal conversion via numpy
gradients instead of PIL's 8-bit-clamped edge filters (which can't properly
center a zero-gradient region at the neutral 128 value without careful
offset handling).
"""

from PIL import Image, ImageFilter, ImageOps, ImageEnhance
import numpy as np
import os

# How pronounced the fake bump detail is — higher = more exaggerated surface
# tilt from the concept art's luminance variation. Tune per-asset if some
# concepts look flatter/bumpier than intended.
NORMAL_STRENGTH = 2.5


def height_to_normal_map(gray_img: Image.Image, strength: float) -> Image.Image:
	"""Real height->normal conversion, not a grayscale copy. Uses numpy
	gradients (central differences) rather than PIL's 8-bit clamped kernel
	filters, which lose precision and can't cleanly center a flat region at
	the neutral value.
	"""
	height = np.asarray(gray_img, dtype=np.float32) / 255.0

	# np.gradient returns (d/d_row, d/d_col) = (dy, dx) for a 2D array
	dy, dx = np.gradient(height)

	nx = -dx * strength
	ny = -dy * strength   # Godot uses OpenGL-style (+Y up) normal maps by
	                       # default — flip this sign if lighting looks
	                       # inverted on the vertical axis once viewed in-editor
	nz = np.ones_like(height)

	length = np.sqrt(nx * nx + ny * ny + nz * nz)
	nx, ny, nz = nx / length, ny / length, nz / length

	# Encode [-1, 1] -> [0, 255], centered at 128 for zero-slope regions
	r = ((nx * 0.5 + 0.5) * 255.0).clip(0, 255).astype(np.uint8)
	g = ((ny * 0.5 + 0.5) * 255.0).clip(0, 255).astype(np.uint8)
	b = ((nz * 0.5 + 0.5) * 255.0).clip(0, 255).astype(np.uint8)

	rgb = np.stack([r, g, b], axis=-1)
	return Image.fromarray(rgb, mode="RGB")


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
	print(f"  - Albedo: {albedo_path}")

	# 2. NORMAL MAP (Linear, PNG) — real height-to-normal conversion, see
	# height_to_normal_map() docstring for what was wrong before.
	gray = ImageOps.grayscale(img)
	# Slight blur first so per-pixel noise in the concept art doesn't turn
	# into harsh single-pixel spikes in the gradient field.
	gray_smoothed = gray.filter(ImageFilter.GaussianBlur(radius=1.5))
	normal = height_to_normal_map(gray_smoothed, NORMAL_STRENGTH)

	normal_path = os.path.join(output_dir, f"{base_name}_normal.png")
	normal.save(normal_path, "PNG")
	print(f"  - Normal: {normal_path}")

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
	print(f"  - Roughness: {roughness_path}")

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
	print(f"  - Emission: {emission_path}")


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
			print(f"X Not found: {input_path}")

	print("\n" + "=" * 60)
	print("PBR generation complete!")
	print("=" * 60)
	print("\nGenerated files in assets/textures/arena/:")
	print("  - *_albedo.webp (sRGB)")
	print("  - *_normal.png (Linear)")
	print("  - *_r_m.png (Linear)")
	print("  - *_emissive.webp (sRGB)")
	print("\nNext: reimport in Godot (right-click each texture > Reimport),")
	print("or just restart the editor — changed files on disk trigger an")
	print("automatic reimport.")


if __name__ == "__main__":
	main()
