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

var is_online := false
var _connecting := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

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
	if multiplayer.multiplayer_peer and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	is_online = false

# ---------- Helpers ----------

func is_ship() -> bool:
	return multiplayer.is_server()   # host = player 1

func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"

func _start_timeout() -> void:
	await get_tree().create_timer(CONNECT_TIMEOUT).timeout
	if _connecting:   # still not connected
		_on_connection_failed()

# ---------- Signal handlers ----------

func _on_peer_connected(id: int) -> void:
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
