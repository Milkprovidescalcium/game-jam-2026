extends "res://scenes/modules/panel_puzzle.gd"

## Landing control (Cockpit): type the two coordinates from Ground Control's
## "Landing for Beginners" page. The left box is N, the right box is E.

@onready var north_input: SpinBox = $NorthInput
@onready var east_input: SpinBox = $EastInput

func _ready() -> void:
	super()
	for input: SpinBox in [north_input, east_input]:
		input.get_line_edit().add_theme_font_size_override("font_size", 52)

func _read_controls() -> Array:
	for input: SpinBox in [north_input, east_input]:
		if input.get_line_edit().has_focus():
			input.apply()   # take a number that is still being typed
	return [int(north_input.value), int(east_input.value)]
