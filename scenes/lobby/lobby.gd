# lobby.gd
extends Control

const SHIP_SCENE := "res://scenes/ship/Body.tscn"
const GROUND_SCENE := "res://scenes/ground_control/ground_control.tscn"

func _ready() -> void:
	Network.player_connected.connect(_on_player_connected)   # ← this one
	Network.connected_ok.connect(_on_connected)
	Network.numbers_received.connect(_on_numbers_received) #grab the function from network? I think
	
	Network.connection_failed.connect(func(): 
		$StatusLabel.text = "Couldn't connect. Check the IP."
		$JoinButton.disabled = false)
		
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
	var err := Network.join(ip)
	if err == OK:
		$StatusLabel.text = "Connecting to %s…" % ip
		$JoinButton.disabled = true
	else:
		$StatusLabel.text = "That's not a valid IP (example: 192.168.1.42)"
		
		
		
func _on_offline() -> void:
	Network.generate_and_send(10, 1, 4)
	
# Client only: connected, now wait for the numbers.
func _on_connected() -> void:
	$StatusLabel.text = "Connected. Waiting for the ship…"
	
# Host only: client joined, so roll the numbers. No scene change here.
func _on_player_connected(_id: int) -> void:
	if multiplayer.is_server():
		Network.generate_and_send(10, 1, 4)  #when the connection is made generate the random numbers

	
#btw leading underscores mean "private"
func _on_numbers_received(_numbers: Array) -> void:
	if Network.is_ship():
		get_tree().change_scene_to_file(SHIP_SCENE)
	else:
		get_tree().change_scene_to_file(GROUND_SCENE)
