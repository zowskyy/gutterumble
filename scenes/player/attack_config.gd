extends Node
# Autoload: AttackConfig
# Single source of truth for combat enums and per-attack frame data.
# Both player_controller.gd and enemy_ai.gd read from here so balance
# changes apply to everyone automatically.

enum CombatState {
	IDLE,
	LOCOMOTION,
	ATTACK_LIGHT,
	ATTACK_HEAVY,
	DODGE,
	BLOCKING,
	HIT_REACT,
	KO,
}

enum AttackPhase {
	NONE,
	WINDUP,
	ACTIVE,
	RECOVERY,
}

# Animation clip names expected in the AnimationTree state machine.
# Map these to actual clips when setting up AnimationTree in the editor.
# Until combat animations exist in the GLB, route all attack states to
# the locomotion_idle clip as a placeholder — fights will still be
# mechanically correct even with wrong visuals.
const ANIM_LOCOMOTION_IDLE  := "locomotion_idle"
const ANIM_LOCOMOTION_TREE  := "locomotion_tree"
const ANIM_DODGE            := "dodge_roll_fwd"
const ANIM_HIT_LIGHT        := "hit_react_light"
const ANIM_HIT_HEAVY        := "hit_react_heavy"
const ANIM_KO               := "ko_front"

# Per-attack frame data. Times are in seconds.
# cancel_start_phase / cancel_end_phase define the window during which
# a buffered input can interrupt this attack and start the next one.
var ATTACK_DATA: Dictionary = {
	"attack_light_01": {
		"damage":             10.0,
		"knockback":          2.5,
		"range":              1.5,
		"windup_time":        0.12,
		"active_time":        0.10,
		"recovery_time":      0.18,
		"can_cancel_into":    ["attack_light_02", "dodge_roll_fwd"],
		"cancel_start_phase": AttackPhase.ACTIVE,
		"cancel_end_phase":   AttackPhase.RECOVERY,
	},
	"attack_light_02": {
		"damage":             13.0,
		"knockback":          3.0,
		"range":              1.5,
		"windup_time":        0.10,
		"active_time":        0.10,
		"recovery_time":      0.20,
		"can_cancel_into":    ["attack_light_03", "dodge_roll_fwd"],
		"cancel_start_phase": AttackPhase.ACTIVE,
		"cancel_end_phase":   AttackPhase.RECOVERY,
	},
	"attack_light_03": {
		"damage":             18.0,
		"knockback":          4.5,
		"range":              1.8,
		"windup_time":        0.16,
		"active_time":        0.12,
		"recovery_time":      0.30,
		"can_cancel_into":    ["dodge_roll_fwd"],
		"cancel_start_phase": AttackPhase.RECOVERY,
		"cancel_end_phase":   AttackPhase.RECOVERY,
	},
	"attack_heavy_01": {
		"damage":             28.0,
		"knockback":          7.0,
		"range":              2.0,
		"windup_time":        0.28,
		"active_time":        0.14,
		"recovery_time":      0.42,
		"can_cancel_into":    [],
		"cancel_start_phase": AttackPhase.NONE,
		"cancel_end_phase":   AttackPhase.NONE,
	},
	"dodge_roll_fwd": {
		"damage":             0.0,
		"knockback":          0.0,
		"range":              0.0,
		"windup_time":        0.05,
		"active_time":        0.22,
		"recovery_time":      0.08,
		"can_cancel_into":    [],
		"cancel_start_phase": AttackPhase.NONE,
		"cancel_end_phase":   AttackPhase.NONE,
	},
}
