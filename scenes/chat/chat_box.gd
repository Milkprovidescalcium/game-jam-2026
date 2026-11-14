extends VBoxContainer

func _ready() -> void:
	$Input.text_submitted.connect(_on_submit)
	ShipNet.message_received.connect(_on_received)
	ShipNet.message_lost.connect(_on_lost)

func send(text: String) -> void:   # public, so ping buttons can use it too
	if text.strip_edges() == "":
		return
	ShipNet.send_message(text)
	_add("[color=black]YOU:[/color] [color=black]%s[/color]" % text)

func _on_submit(text: String) -> void:
	send(text)
	$Input.clear()
	$Input.grab_focus()   

func _on_received(text: String, from_ship: bool) -> void:
	var who := "SHIP" if from_ship else "GROUND"
	_add("[color=cyan]%s:[/color] %s" % [who, text])

func _on_lost(text: String) -> void:
	_add("[color=red]SIGNAL LOST — not sent:[/color] %s" % text)

func _add(line: String) -> void:
	$MessageLog.append_text(line + "\n")
