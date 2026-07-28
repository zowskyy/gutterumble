#!/usr/bin/env python3

GANGS = ["Serpents", "Vipers", "Rats", "Tigers"]
ARCHETYPES = ["Leader", "Grunt", "Lookout", "Tank", "Speedster"]

ARCHETYPE_DETAILS = {
	"Leader": "Commanding presence, scars, authoritative stance, enhanced gear",
	"Grunt": "Average build, eager expression, standard gang outfit",
	"Lookout": "Lean build, alert posture, scanner-focused gear",
	"Tank": "Large muscular build, intimidating, heavy armor and gear",
	"Speedster": "Lean and agile build, dynamic pose, minimal gear",
}

def generate_prompts():
	for gang in GANGS:
		for archetype in ARCHETYPES:
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
			
			print(f"\n{gang} - {archetype}:")
			print("\n".join(lines))

if __name__ == "__main__":
	generate_prompts()
