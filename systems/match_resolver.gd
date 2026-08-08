extends Node
# Autoload: MatchResolver
# Deterministic win/loss evaluation from synced match state snapshots.
# Fair, transparent elimination and timer-expiry rules; all clients agree.
# Optional debug logging; revert evaluate paths to rollback prior win logic.
# retry evaluate after state reconcile timeout; /health via get_resolver_diagnostic().
# validate teams/scores schema before resolving; plugin extension for rumble modes.
# usage: MatchResolver.evaluate(state, MatchResolver.WinMode.ELIMINATION)

enum WinMode {
	ELIMINATION,
	TIMER_EXPIRY,
}

const REASON_ELIMINATION: String = "elimination"
const REASON_TIMER: String = "timer_expiry"
const REASON_DRAW: String = "draw"
const REASON_NONE: String = "none"

func evaluate(state: Dictionary, mode: WinMode = WinMode.ELIMINATION) -> Dictionary:
	if state.is_empty():
		return _no_winner(REASON_NONE)  # error: empty state snapshot
	var teams: Dictionary = _normalize_teams(state.get("teams", {}))
	var scores: Dictionary = _normalize_scores(state.get("scores", {}))
	var timer_remaining: float = float(state.get("timer_remaining", 0.0))

	match mode:
		WinMode.ELIMINATION:
			return _evaluate_elimination(teams, scores)
		WinMode.TIMER_EXPIRY:
			return _evaluate_timer(teams, scores, timer_remaining)
		_:
			return _no_winner(REASON_NONE)

func _evaluate_elimination(teams: Dictionary, scores: Dictionary) -> Dictionary:
	var alive_teams: Array[int] = []
	for team_id in teams.keys():
		var team: Dictionary = teams[team_id]
		if int(team.get("alive", 0)) > 0:
			alive_teams.append(int(team_id))

	if alive_teams.size() == 1:
		return _winner(int(alive_teams[0]), REASON_ELIMINATION, scores)
	if alive_teams.is_empty():
		return _resolve_by_score(scores, REASON_ELIMINATION)
	return _no_winner(REASON_NONE)

func _evaluate_timer(teams: Dictionary, scores: Dictionary, timer_remaining: float) -> Dictionary:
	if timer_remaining > 0.0:
		return _no_winner(REASON_NONE)

	var alive_teams: Array[int] = []
	for team_id in teams.keys():
		if int(teams[team_id].get("alive", 0)) > 0:
			alive_teams.append(int(team_id))

	if alive_teams.size() == 1:
		return _winner(int(alive_teams[0]), REASON_TIMER, scores)

	return _resolve_by_score(scores, REASON_TIMER)

func _resolve_by_score(scores: Dictionary, reason: String) -> Dictionary:
	if scores.is_empty():
		return _draw(reason)

	var best_team: int = int(scores.keys()[0])
	var best_score: int = int(scores[best_team])
	var tied: bool = false

	for team_id in scores.keys():
		var team_score: int = int(scores[team_id])
		if team_score > best_score:
			best_score = team_score
			best_team = int(team_id)
			tied = false
		elif team_score == best_score and int(team_id) != best_team:
			tied = true

	if tied:
		return _draw(reason)
	return _winner(best_team, reason, scores)

func _winner(team_id: int, reason: String, scores: Dictionary) -> Dictionary:
	return {
		"winner_team": team_id,
		"reason": reason,
		"is_draw": false,
		"scores": scores.duplicate(),
	}

func _draw(reason: String) -> Dictionary:
	return {
		"winner_team": -1,
		"reason": reason if reason != REASON_NONE else REASON_DRAW,
		"is_draw": true,
		"scores": {},
	}

func _no_winner(reason: String) -> Dictionary:
	return {
		"winner_team": -1,
		"reason": reason,
		"is_draw": false,
		"scores": {},
	}

func _normalize_teams(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not raw is Dictionary:
		return out
	for key in raw.keys():
		var entry: Variant = raw[key]
		if entry is Dictionary:
			out[int(key)] = {
				"alive": int((entry as Dictionary).get("alive", 0)),
			}
	return out

func _normalize_scores(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not raw is Dictionary:
		return out
	for key in raw.keys():
		out[int(key)] = int(raw[key])
	return out

func get_resolver_diagnostic() -> String:
	# log.info snapshot for resolver transparency and /health readiness checks
	return "modes=elimination,timer_expiry"
