# network.gd (Autoload: Network)
extends Node

signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal connected_ok
signal connection_failed
signal server_closed

const PORT := 7777
const MAX_CLIENTS := 1  # just ground control

var is_online := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func(): connected_ok.emit())
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Could not host: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	is_online = true
	return OK

func join(ip: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		push_error("Could not join: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	is_online = true
	return OK

func leave() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	is_online = false

func is_ship() -> bool:
	return multiplayer.is_server()  # host = player 1

func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			return ip
	return "127.0.0.1"

func _on_peer_connected(id: int) -> void:
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	player_disconnected.emit(id)

func _on_connection_failed() -> void:
	leave()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	leave()
	server_closed.emit()
