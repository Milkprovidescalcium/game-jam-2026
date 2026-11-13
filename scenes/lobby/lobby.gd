# lobby.gd
extends Control

const SHIP_SCENE := "res://scenes/ship.tscn"
const GROUND_SCENE := "res://scenes/ground_control.tscn"

func _ready() -> void:
	Network.player_connected.connect(_on_player_connected)
	Network.connected_ok.connect(_on_connected)
	Network.connection_failed.connect(func(): $StatusLabel.text = "Couldn't connect. Check the IP.")
	$HostButton.pressed.connect(_on_host)
	$JoinButton.pressed.connect(_on_join)
	$OfflineButton.pressed.connect(func(): get_tree().change_scene_to_file(SHIP_SCENE))

func _on_host() -> void:
	if Network.host() == OK:
		$StatusLabel.text = "Hosting on %s — waiting for ground control…" % Network.get_local_ip()

func _on_join() -> void:
	var ip: String = $IPInput.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	if Network.join(ip) == OK:
		$StatusLabel.text = "Connecting to %s…" % ip

func _on_player_connected(_id: int) -> void:
	if Network.is_ship():
		get_tree().change_scene_to_file(SHIP_SCENE)

func _on_connected() -> void:
	get_tree().change_scene_to_file(GROUND_SCENE)
