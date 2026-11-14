extends "res://scenes/modules/panel_puzzle.gd"

## Ventilation / oxygen (Left Wing): three knobs with four directions each.
## The oxygen bar shows the level: 1, 2 or 3 segments full, exactly like the
## rows on Ground Control's "Oxygene 101" page.

const OXYGEN_COLOR := Color(0.2, 0.9, 0.3)

@onready var knobs: Node = $Knobs
@onready var oxygen_bar: Node = $StatusPanel/Symptom/Bar

func _read_controls() -> Array:
	var values: Array = []
	for knob in knobs.get_children():
		values.append(knob.value)   # 0 up, 1 right, 2 down, 3 left
	return values

func _show_symptom(level: int) -> void:
	_light_segments(oxygen_bar, level, OXYGEN_COLOR)
