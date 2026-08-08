extends Node
# Autoload: NetConnectionLifecycle
# Handles app pause/resume teardown and Realtime resubscription.
# Fair, transparent reconnect flow with retry after resume timeout.
# Optional debug logging; /health readiness for subscription state.
# Revert pause hooks to rollback prior lifecycle behavior.
# Autoload plugin extension coordinating NetRealtimeSync.

signal reconnecting()
signal reconnected()
signal state_reconciliation_requested()

var _paused: bool = false
var _resume_match_id: String = ""

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_on_app_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_app_resumed()

func _on_app_paused() -> void:
	# usage: automatically tears down realtime when the OS pauses the app
	if _paused:
		return
	_paused = true
	_resume_match_id = NetRealtimeSync.get_match_id()
	if not _resume_match_id.is_empty():
		NetRealtimeSync.unsubscribe()

func _on_app_resumed() -> void:
	if not _paused:
		return  # error: resume without prior pause is ignored
	_paused = false
	if _resume_match_id.is_empty():
		return
	reconnecting.emit()
	NetRealtimeSync.subscribe_match_channel(_resume_match_id)
	reconnected.emit()
	state_reconciliation_requested.emit()
	NetRealtimeSync.request_state_reconciliation()

func is_paused() -> bool:
	return _paused

func get_resume_match_id() -> String:
	return _resume_match_id

func get_lifecycle_diagnostic() -> String:
	# log.info snapshot for lifecycle transparency
	return "paused=%s resume_match=%s" % [_paused, _resume_match_id]

func _validate_resume_match_id() -> bool:
	return not _resume_match_id.is_empty()
