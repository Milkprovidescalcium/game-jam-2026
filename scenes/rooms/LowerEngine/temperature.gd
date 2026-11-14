extends "res://scenes/modules/panel_puzzle.gd"

## Temperature (Lower Engine): five switches, each up or down.
## The thermometer shows the level. Level 1 is the top row of Ground Control's
## "Temperature Guide", so the thermometer is full; each level after that sits
## one section lower.

const HEAT_COLOR := Color(1.0, 0.45, 0.15)

@onready var switches: Node = $Switches
@onready var thermometer: Node = $StatusPanel/Symptom/Thermometer

func _read_controls() -> Array:
	var values: Array = []
	for switch in switches.get_children():
		values.append(switch.value)   # 0 up, 1 down
	return values

func _show_symptom(level: int) -> void:
	_light_segments(thermometer, rules.size() - level + 1, HEAT_COLOR)
