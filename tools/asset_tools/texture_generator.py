#!/usr/bin/env python3
"""Procedural texture generator for GUTTERUMBLE assets."""

from PIL import Image, ImageDraw, ImageFilter
import os
import random

def generate_concrete_texture(width=1024, height=1024, filename="concrete.png"):
	"""Generate a gritty concrete texture."""
	img = Image.new("RGB", (width, height), (100, 100, 105))
	draw = ImageDraw.Draw(img)
	
	# Add noise
	for _ in range(500):
		x = random.randint(0, width)
		y = random.randint(0, height)
		gray = random.randint(80, 120)
		draw.ellipse([x, y, x+10, y+10], fill=(gray, gray, gray))
	
	# Add blur for roughness
	img = img.filter(ImageFilter.GaussianBlur(radius=3))
	img.save(filename)
	print(f"Generated {filename}")

def generate_metal_texture(width=1024, height=1024, filename="metal.png"):
	"""Generate a metallic texture."""
	img = Image.new("RGB", (width, height), (150, 150, 155))
	draw = ImageDraw.Draw(img)
	
	# Horizontal lines
	for y in range(0, height, 5):
		gray = random.randint(140, 160)
		draw.line([(0, y), (width, y)], fill=(gray, gray, gray), width=1)
	
	img = img.filter(ImageFilter.GaussianBlur(radius=1))
	img.save(filename)
	print(f"Generated {filename}")

def generate_leather_texture(width=1024, height=1024, filename="leather.png"):
	"""Generate a leather texture."""
	img = Image.new("RGB", (width, height), (60, 40, 30))
	draw = ImageDraw.Draw(img)
	
	# Random scratches and marks
	for _ in range(200):
		x1 = random.randint(0, width)
		y1 = random.randint(0, height)
		x2 = x1 + random.randint(5, 30)
		y2 = y1 + random.randint(-5, 5)
		draw.line([(x1, y1), (x2, y2)], fill=(40, 20, 10), width=1)
	
	img = img.filter(ImageFilter.GaussianBlur(radius=2))
	img.save(filename)
	print(f"Generated {filename}")

if __name__ == "__main__":
	os.makedirs("assets/textures/generated", exist_ok=True)
	generate_concrete_texture(filename="assets/textures/generated/concrete.png")
	generate_metal_texture(filename="assets/textures/generated/metal.png")
	generate_leather_texture(filename="assets/textures/generated/leather.png")
	print("Texture generation complete!")
