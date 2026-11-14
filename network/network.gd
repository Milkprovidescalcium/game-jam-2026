# network.gd (Autoload: Network)
extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connected_ok
signal connection_failed
signal server_closed

const PORT := 7777
const MAX_CLIENTS := 1          # just ground control
const CONNECT_TIMEOUT := 5.0    # seconds before giving up on joining
const PEER_TIMEOUT_MS := 3000   # a player who crashes / loses wifi counts as gone after ~3-6 s
const LOBBY_SCENE := "res://scenes/lobby/lobby.tscn"

var is_online := false
var last_message := ""          # why the last game ended; the lobby shows it once
var _connecting := false
var _join_attempt := 0          # so an old join timeout can't cancel a newer attempt

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _notification(what: int) -> void:
	# Closing the window: say goodbye first so the other player finds out
	# straight away instead of waiting for a timeout.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		leave()

# <------random seed ------>

signal numbers_received(numbers: Array)

var numbers: Array = []

func generate_and_send(count: int, min_val: int, max_val: int) -> void:
	if not multiplayer.is_server():
		return
	var generated: Array = []
	for i in count:
		generated.append(randi_range(min_val, max_val))
	_receive_numbers.rpc(generated) #sends a signal across network

@rpc("authority", "call_local", "reliable") #just configs the connection
func _receive_numbers(new_numbers: Array) -> void:
	numbers = new_numbers
	numbers_received.emit(numbers)

# <------random seed -----/>

# ---------- Host / join / leave ----------

func host() -> Error:
	leave()   # close any old connection first
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Could not host: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	is_online = true
	return OK

func join(ip: String) -> Error:
	ip = ip.strip_edges()
	if ip.to_lower() == "localhost":
		ip = "127.0.0.1"
	if not ip.is_valid_ip_address():
		push_warning("Not a valid IP: %s" % ip)
		return ERR_INVALID_PARAMETER
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		push_error("Could not join: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	is_online = true
	_connecting = true
	_start_timeout()
	return OK

func leave() -> void:
	_connecting = false
	_join_attempt += 1   # cancels any join timeout that is still counting
	if multiplayer.multiplayer_peer and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	is_online = false

## The game is over because someone left: drop the connection and send this
## player back to the lobby, which shows `message`.
func end_session(message: String) -> void:
	last_message = message
	_end_session_now.call_deferred()   # after Godot finishes handling the disconnect

func _end_session_now() -> void:
	leave()
	get_tree().change_scene_to_file(LOBBY_SCENE)

# ---------- Helpers ----------

func is_ship() -> bool:
	return multiplayer.is_server()   # host = player 1

## Every address on this computer that another computer on the same network
## could join with, most likely one first (home wifi / LAN before VPNs and
## virtual adapters such as WSL or Docker).
func get_local_ips() -> Array[String]:
	var home: Array[String] = []
	var other: Array[String] = []
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168."):
			if not ip in home:
				home.append(ip)
		elif ip.begins_with("10.") or _is_private_172(ip):
			if not ip in other:
				other.append(ip)
	return home + other

func get_local_ip() -> String:
	var ips := get_local_ips()
	return ips[0] if not ips.is_empty() else "127.0.0.1"

func _is_private_172(ip: String) -> bool:
	var parts := ip.split(".")
	return parts.size() == 4 and parts[0] == "172" and int(parts[1]) >= 16 and int(parts[1]) <= 31

func _start_timeout() -> void:
	var attempt := _join_attempt
	await get_tree().create_timer(CONNECT_TIMEOUT).timeout
	if _connecting and attempt == _join_attempt:   # this attempt is still not connected
		_on_connection_failed()

# Notice a crashed / unplugged player after a few seconds instead of ~30
func _use_short_timeout(peer_id: int) -> void:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet == null:
		return
	var peer := enet.get_peer(peer_id)
	if peer:
		peer.set_timeout(8, PEER_TIMEOUT_MS, PEER_TIMEOUT_MS * 2)

# ---------- Signal handlers ----------

func _on_peer_connected(id: int) -> void:
	_use_short_timeout(id)
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	_connecting = false
	connected_ok.emit()

func _on_connection_failed() -> void:
	if not _connecting:
		return   # already handled
	_connecting = false
	leave.call_deferred()   # shut down after Godot finishes, not during
	connection_failed.emit()

func _on_server_disconnected() -> void:
	leave.call_deferred()
	server_closed.emit()
