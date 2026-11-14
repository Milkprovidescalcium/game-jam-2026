# ship_net.gd (Autoload: ShipNet)
extends Node

# ---------- Signals the UI listens to ----------
# Both players
signal message_received(text: String, from_ship: bool)
signal message_lost(text: String)
signal game_started(seed_value: int)
signal time_changed(seconds_left: int)
signal game_ended(won: bool)
signal signal_lost_changed(lost: bool)
# Ground control only
signal room_status_changed(room_id: String, broken: bool)
signal player_moved(room_id: String)
signal puzzle_info(room_id: String, info: Dictionary)
signal ship_health_changed(value: int)
# Ship only
signal ground_ready
signal manual_received(manual: Dictionary)	

@export var signal_delay := 3.0   # seconds, the "speed of light" delay
var signal_lost := false           # true during orbit blackout
var ground_is_ready := false       # ship side: ground control has loaded its scene
var manual := {}

func _ready() -> void:
	multiplayer.peer_disconnected.connect(func(_id): ground_is_ready = false)

# Back to a clean slate; the lobby calls this before every new game
func reset() -> void:
	signal_lost = false
	ground_is_ready = false

func is_ground() -> bool:
	return not multiplayer.is_server()

# =====================================================
# CHAT: both players -> the other player
# =====================================================

func send_message(text: String) -> void:
	if signal_lost:
		message_lost.emit(text)   # lost in space
		return
	_deliver_message.rpc(text)

@rpc("any_peer", "call_remote", "reliable")
func _deliver_message(text: String) -> void:
	var from_ship := multiplayer.get_remote_sender_id() == 1   # host = ship
	await get_tree().create_timer(signal_delay).timeout
	message_received.emit(text, from_ship)

# =====================================================
# GROUND CONTROL -> SHIP: "my scene is loaded, start the round"
# =====================================================

func notify_ground_ready() -> void:
	_ground_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _ground_ready() -> void:
	ground_is_ready = true
	ground_ready.emit()

# =====================================================
# SHIP -> BOTH PLAYERS (call these only on the host)
# =====================================================

func start_game(seed_value: int) -> void:
	_game_started.rpc(seed_value)

@rpc("authority", "call_local", "reliable")
func _game_started(seed_value: int) -> void:
	game_started.emit(seed_value)

func set_time_left(seconds: int) -> void:
	_time_left.rpc(seconds)

@rpc("authority", "call_local", "reliable")
func _time_left(seconds: int) -> void:
	time_changed.emit(seconds)

func set_signal_lost(lost: bool) -> void:
	_signal_lost.rpc(lost)

@rpc("authority", "call_local", "reliable")
func _signal_lost(lost: bool) -> void:
	signal_lost = lost
	signal_lost_changed.emit(lost)

func end_game(won: bool) -> void:
	_end.rpc(won)

@rpc("authority", "call_local", "reliable")
func _end(won: bool) -> void:
	game_ended.emit(won)

# =====================================================
# SHIP -> GROUND CONTROL ONLY (the ship never sees these)
# =====================================================

func set_room_broken(room_id: String, broken: bool) -> void:
	_room_status.rpc(room_id, broken)

@rpc("authority", "call_remote", "reliable")
func _room_status(room_id: String, broken: bool) -> void:
	room_status_changed.emit(room_id, broken)

func report_player_room(room_id: String) -> void:
	_player_room.rpc(room_id)

@rpc("authority", "call_remote", "reliable")
func _player_room(room_id: String) -> void:
	player_moved.emit(room_id)

func send_puzzle_info(room_id: String, info: Dictionary) -> void:
	_puzzle_info.rpc(room_id, info)   # e.g. {"puzzle": "Temperature", "target": 23}

@rpc("authority", "call_remote", "reliable")
func _puzzle_info(room_id: String, info: Dictionary) -> void:
	puzzle_info.emit(room_id, info)

func set_ship_health(value: int) -> void:
	_health.rpc(value)

@rpc("authority", "call_remote", "reliable")
func _health(value: int) -> void:
	ship_health_changed.emit(value)
	
func send_manual(data: Dictionary) -> void:
	_manual.rpc(data)

@rpc("authority", "call_remote", "reliable")
func _manual(data: Dictionary) -> void:
	manual = data
	manual_received.emit(data)
