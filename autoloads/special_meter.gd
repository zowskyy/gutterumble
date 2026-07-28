extends Node
# Autoload: SpecialMeter
# Musou-style charge gauge — the player's "unleash" resource.
# Fills from landing hits AND from taking damage (the classic Warriors/Musou
# rule: aggression and survival both build toward the payoff, not just offense).
#
# Deliberately persists across round transitions within a match (only
# RoundManager.reset()-adjacent arena boot calls SpecialMeter.reset()) —
# banking a full gauge at a round's end means you open the next round with
# an instant AOE, which rewards the same "never let up" playstyle as the
# Gutter Streak combo.

signal charge_changed(value: float, max_value: float)
signal activated

const MAX_CHARGE := 100.0
const CHARGE_PER_LIGHT_HIT      := 6.0
const CHARGE_PER_HEAVY_HIT      := 10.0
const CHARGE_PER_DAMAGE_TAKEN   := 8.0

var charge: float = 0.0

func add_charge(amount: float) -> void:
	charge = clampf(charge + amount, 0.0, MAX_CHARGE)
	charge_changed.emit(charge, MAX_CHARGE)

func is_full() -> bool:
	return charge >= MAX_CHARGE

func try_activate() -> bool:
	if not is_full():
		return false
	charge = 0.0
	charge_changed.emit(charge, MAX_CHARGE)
	activated.emit()
	return true

func reset() -> void:
	charge = 0.0
	charge_changed.emit(charge, MAX_CHARGE)
