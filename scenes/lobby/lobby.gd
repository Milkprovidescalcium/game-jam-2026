# lobby.gd
extends Control

const SHIP_SCENE := "res://scenes/ship/ship.tscn"
const GROUND_SCENE := "res://scenes/ground_control/ground_control_nico.tscn"

func _ready() -> void:
	# Always start from a clean slate (we may be coming back from a game)
	Network.leave()
	ShipNet.reset()

	Network.player_connected.connect(_on_player_connected)   # ← this one
	Network.connected_ok.connect(_on_connected)
	Network.numbers_received.connect(_on_numbers_received) #grab the function from network? I think
	Network.connection_failed.connect(_on_connection_failed)
	Network.server_closed.connect(_on_server_closed)

	$HostButton.pressed.connect(_on_host)
	$JoinButton.pressed.connect(_on_join)
	$OfflineButton.pressed.connect(_on_offline)
	$IPInput.text_submitted.connect(func(_text): _on_join())
	$IPInput.placeholder_text = "Host's IP (leave empty if the host is this computer)"

	# Came back because the other player left? Say so.
	if Network.last_message != "":
		$StatusLabel.text = Network.last_message
		Network.last_message = ""

func _on_host() -> void:
	$JoinButton.disabled = false
	var err: Error = Network.host()
	if err == OK:
		var ips: Array[String] = Network.get_local_ips()
		if ips.is_empty():
			$StatusLabel.text = "Hosting, but no network found - only this computer can join."
		else:
			$StatusLabel.text = "Hosting - Ground Control joins with: %s" % " or ".join(ips)
	else:
		$StatusLabel.text = "Couldn't host - port %d is busy. Is another copy of the game already hosting?" % Network.PORT

func _on_join() -> void:
	if $JoinButton.disabled:
		return   # already trying
	var ip: String = $IPInput.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	var err: Error = Network.join(ip)
	if err == OK:
		$StatusLabel.text = "Connecting to %s…" % ip
		$JoinButton.disabled = true
	else:
		$StatusLabel.text = "That's not a valid IP (example: 192.168.1.42)"

# Solo test run: just the ship, nobody to wait for
func _on_offline() -> void:
	Network.leave()   # in case HOST or JOIN was pressed first
	get_tree().change_scene_to_file(SHIP_SCENE)

func _on_connection_failed() -> void:
	$StatusLabel.text = "Couldn't connect. Check the IP and that the host pressed HOST."
	$JoinButton.disabled = false

# Client only: the host went away while we were still in the lobby
func _on_server_closed() -> void:
	$StatusLabel.text = "The host closed the game."
	$JoinButton.disabled = false

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
