# ship_net.gd (Autoload: ShipNet)
extends Node

# Signals the UI listens to
signal message_received(text: String)
signal message_lost(text: String)
signal room_status_changed(room_id: String, broken: bool)
signal player_moved(room_id: String)
signal puzzle_info(room_id: String, info: Dictionary)
signal ship_health_changed(value: int)
signal game_ended(won: bool)
signal signal_lost_changed(lost: bool)

@export var signal_delay := 3.0      # seconds, the "speed of light" delay
var signal_lost := false              # true during orbit blackout

# ---------- Ground control -> ship ----------

func send_message(text: String) -> void:
	if signal_lost:
		message_lost.emit(text)
		return  # lost in space
	_deliver_message.rpc(text)

@rpc("any_peer", "call_remote", "reliable")
func _deliver_message(text: String) -> void:
	var from_ship := multiplayer.get_remote_sender_id() == 1   # host = ship
	await get_tree().create_timer(signal_delay).timeout
	message_received.emit(text, from_ship)

# ---------- Ship -> ground control ----------
# Call these only on the host (the ship).

func set_room_broken(room_id: String, broken: bool) -> void:
	_room_status.rpc(room_id, broken)

@rpc("authority", "call_local", "reliable")
func _room_status(room_id: String, broken: bool) -> void:
	room_status_changed.emit(room_id, broken)

func report_player_room(room_id: String) -> void:
	_player_room.rpc(room_id)

@rpc("authority", "call_local", "reliable")
func _player_room(room_id: String) -> void:
	player_moved.emit(room_id)

func send_puzzle_info(room_id: String, info: Dictionary) -> void:
	_puzzle_info.rpc(room_id, info)  # e.g. {"code": "4-7-1", "wires": ["red", "blue"]}

@rpc("authority", "call_remote", "reliable")
func _puzzle_info(room_id: String, info: Dictionary) -> void:
	puzzle_info.emit(room_id, info)

func set_ship_health(value: int) -> void:
	_health.rpc(value)

@rpc("authority", "call_local", "reliable")
func _health(value: int) -> void:
	ship_health_changed.emit(value)

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
	
