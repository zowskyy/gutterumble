#!/usr/bin/env python3
"""
Export character prompts to individual text files for easy copy-paste workflow.
"""

import os

GANGS = ["Serpents", "Vipers", "Rats", "Tigers"]
ARCHETYPES = ["Leader", "Grunt", "Lookout", "Tank", "Speedster"]

ARCHETYPE_DETAILS = {
	"Leader": "Commanding presence, scars, authoritative stance, enhanced gear",
	"Grunt": "Average build, eager expression, standard gang outfit",
	"Lookout": "Lean build, alert posture, scanner-focused gear",
	"Tank": "Large muscular build, intimidating, heavy armor and gear",
	"Speedster": "Lean and agile build, dynamic pose, minimal gear",
}

def build_prompt(gang, archetype):
	details = ARCHETYPE_DETAILS.get(archetype, "")
	lines = [
		"GUTTERUMBLE Character Concept:",
		"- Game: Street gang brawler",
		"- Style: Cel-shaded, gritty urban aesthetic",
		"- Format: Full-body character concept art",
		"- Resolution: 2048 by 2048",
		"- Anatomy: Realistic human proportions",
		f"- Gang: {gang}",
		f"- Role: {archetype}",
		"- Era: Urban street gang setting",
		"- Clothing: Leather jackets, jeans, boots, gang colors",
		f"- Characteristics: {details}",
		"- Detail: High-quality, ready for 3D modeling",
		"- Quality: Professional concept art level",
	]
	return "\n".join(lines)

def main():
	output_dir = "docs/character_prompts"
	os.makedirs(output_dir, exist_ok=True)
	
	index_lines = ["# GUTTERUMBLE Character Concept Checklist\n"]
	count = 0
	
	for gang in GANGS:
		index_lines.append(f"\n## {gang}\n")
		for archetype in ARCHETYPES:
			count += 1
			filename = f"{gang.lower()}_{archetype.lower()}.txt"
			filepath = os.path.join(output_dir, filename)
			
			prompt = build_prompt(gang, archetype)
			
			with open(filepath, "w", encoding="utf-8") as f:
				f.write(prompt)
			
			index_lines.append(f"- [ ] {count:02d}. {gang} {archetype} -> `{filename}`")
			print(f"✓ Created: {filename}")
	
	index_path = os.path.join(output_dir, "README.md")
	with open(index_path, "w", encoding="utf-8") as f:
		f.write("\n".join(index_lines))
	
	print(f"\n✓ Created checklist: {index_path}")
	print(f"\nTotal: {count} character prompt files")
	print(f"Location: {output_dir}/")
	print("\nWorkflow:")
	print("1. Open docs/character_prompts/README.md as your checklist")
	print("2. Open each .txt file, copy content to Hugging Face")
	print("3. Download image, save to assets/reference/{gang}_{archetype}.webp")
	print("4. Check off the box in README.md")
	print("5. Repeat for all 20")

if __name__ == "__main__":
	main()