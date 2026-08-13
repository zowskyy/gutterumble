extends Node
# =============================================================================
# Autoload: RoundManager — CANONICAL match-flow (KEEP)
# Live arenas (rumble_arena_back_alley.gd) call start_round() / record_win().
# MatchResolver is test-only / DEFER — do not dual-wire both into arenas.
# See docs/engineering/CANONICAL_ARCHITECTURE.md.
# =============================================================================
# Best-of-3 round tracking. Emits signals the arena and HUD listen to.

signal round_started(round_num: int)
signal round_over(player_won: bool, player_score: int, enemy_score: int)
signal match_over(player_won: bool)

const ROUNDS_TO_WIN := 2   # first to 2 wins takes the match

var player_wins: int = 0
var enemy_wins: int  = 0
var current_round: int = 1
var match_active: bool = false

func reset() -> void:
	player_wins   = 0
	enemy_wins    = 0
	current_round = 1
	match_active  = true

func start_round() -> void:
	round_started.emit(current_round)
	AudioManager.play_sfx("countdown")

func record_win(player_won: bool) -> void:
	if not match_active:
		return
	if player_won:
		player_wins += 1
		AudioManager.play_sfx("win")
	else:
		enemy_wins += 1
		AudioManager.play_sfx("lose")

	round_over.emit(player_won, player_wins, enemy_wins)

	if player_wins >= ROUNDS_TO_WIN or enemy_wins >= ROUNDS_TO_WIN:
		match_active = false
		match_over.emit(player_wins >= ROUNDS_TO_WIN)
	else:
		current_round += 1

func is_match_over() -> bool:
	return not match_active
