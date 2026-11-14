extends ProgressBar

func _ready() -> void:
	ShipNet.ship_health_changed.connect(_on_health_changed)
	ShipNet.game_started.connect(func(_seed): _on_health_changed(100))
	_on_health_changed(100)

func _on_health_changed(hp: int) -> void:
	value = hp
	var fill := StyleBoxFlat.new()
	if hp > 60:
		fill.bg_color = Color(0.2, 0.8, 0.3)    # green
	elif hp > 30:
		fill.bg_color = Color(0.95, 0.7, 0.1)   # yellow
	else:
		fill.bg_color = Color(0.9, 0.15, 0.15)  # red
	add_theme_stylebox_override("fill", fill)
