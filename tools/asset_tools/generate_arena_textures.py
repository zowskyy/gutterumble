#!/usr/bin/env python3
import os

ARENAS = {
	"subway_platform": "Underground subway station platform with industrial lighting",
	"rooftop": "Abandoned building rooftop at night with neon city glow",
	"warehouse": "Industrial warehouse with stacked containers and harsh lighting",
	"parking_garage": "Multi-level concrete parking structure with fluorescent lights",
	"burning_lot": "Abandoned lot with fire barrels and smoke",
}

def generate_prompts():
	for arena_name, description in ARENAS.items():
		lines = [
			"GUTTERUMBLE Arena Texture Specification:",
			"- Engine: Godot 4.7 Mobile",
			"- Resolution: 2048 by 2048",
			"- Format: PNG or WebP",
			"- Style: Cel-shaded, gritty urban street setting",
			"- Color space: sRGB for albedo, Linear for normal data",
			"- Compression: WebP quality 85",
			f"- Arena: {arena_name}",
			f"- Description: {description}",
			"",
			"Texture Layout:",
			"- Ground and floor area",
			"- Wall structures",
			"- Graffiti and gang marks",
			"- Neon lighting accents",
			"- Weathering, rust, decay effects",
			"",
			"Palette: Deep shadows with neon accents",
			"Density: High detail that tiles smoothly",
		]
		
		print(f"\n{arena_name}:")
		print("\n".join(lines))

if __name__ == "__main__":
	generate_prompts()
