extends Node
# Autoload: NetConnectionLifecycle
# Handles app pause/resume teardown and Realtime resubscription.

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
	if _paused:
		return
	_paused = true
	_resume_match_id = NetRealtimeSync.get_match_id()
	if not _resume_match_id.is_empty():
		NetRealtimeSync.unsubscribe()

func _on_app_resumed() -> void:
	if not _paused:
		return
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
