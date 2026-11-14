extends Node2D

## Player 2 (ground control). The map, timer, health bar and chat each listen
## to ShipNet on their own; this script just handles the connection.

func _ready() -> void:
	Network.server_closed.connect(_on_server_closed)
	if Network.is_online:
		ShipNet.notify_ground_ready()   # tells the ship it can start the round

	print("ground control sees: ", Network.numbers)

# The ship player quit or lost connection: the game is over for us too
func _on_server_closed() -> void:
	Network.end_session("The ship disconnected - game over.")
