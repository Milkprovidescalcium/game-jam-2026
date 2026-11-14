extends Label

const WARNING_TIME := 30   # turns red under 30 seconds

func _ready() -> void:
	ShipNet.time_changed.connect(_on_time_changed)
	ShipNet.game_ended.connect(_on_game_ended)
	

func _on_time_changed(seconds: int) -> void:
	text = "%d:%02d" % [seconds / 60, seconds % 60]
	if seconds <= WARNING_TIME:
		modulate = Color.RED if seconds % 2 == 0 else Color.WHITE   # blink
	else:
		modulate = Color.WHITE

func _on_game_ended(won: bool) -> void:
	modulate = Color.GREEN if won else Color.RED
	text = "SURVIVED" if won else "SHIP LOST"
