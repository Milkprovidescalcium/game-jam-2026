extends Node2D

## Player 2 (ground control). The map, timer, health bar and chat each listen
## to ShipNet on their own; this script just handles the connection.

const LOBBY_SCENE := "res://scenes/lobby/lobby.tscn"

func _ready() -> void:
	Network.server_closed.connect(_on_server_closed)
	if Network.is_online:
		ShipNet.notify_ground_ready()   # tells the ship it can start the round

func _on_server_closed() -> void:
	get_tree().change_scene_to_file(LOBBY_SCENE)
