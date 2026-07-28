extends Node

@export var port: int = 8910
@export var max_players: int = 16

var server: ENetMultiplayerPeer
var players: Dictionary = {}
var match_time: float = 0.0
var match_active: bool = false

func _ready() -> void:
	if OS.has_feature("server"):
		start_server()

func start_server() -> void:
	server = ENetMultiplayerPeer.new()
	var error: Error = server.create_server(port, max_players)
	if error != OK:
		push_error("Failed to start server on port " + str(port))
		return
	multiplayer.multiplayer_peer = server
	push_warning("Match server started on port " + str(port))

func _process(delta: float) -> void:
	if match_active:
		match_time += delta

func broadcast_state(state: Dictionary) -> void:
	_on_receive_state.rpc(state)

@rpc("any_peer", "unreliable")
func player_action(action: String, data: Dictionary) -> void:
	var peer_id: int = multiplayer.get_remote_sender_id()
	if peer_id not in players:
		return

@rpc("any_peer")
func player_attack(target_id: int, attack_type: String) -> void:
	var peer_id: int = multiplayer.get_remote_sender_id()
	var attacker: Dictionary = players.get(peer_id, {})
	var target: Dictionary = players.get(target_id, {})
	
	if attacker.is_empty() or target.is_empty():
		return

@rpc
func _on_receive_state(state: Dictionary) -> void:
	pass
