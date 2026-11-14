extends "res://scenes/modules/panel_puzzle.gd"

## Radiation (Right Wing): press the four colours in the right order.
## The panel names the radiation type (ALPHA, BETA, DELTA), which matches the
## rows on Ground Control's "Radiation" page.

const LEVEL_NAMES := ["ALPHA", "BETA", "DELTA"]

# Same order as radiation_textures in instructions_node.gd: value 0 = blue,
# 1 = red, 2 = green, 3 = yellow.
const COLOR_TEXTURES: Array[Texture2D] = [
	preload("res://art/rooms/ButtonBlue.png"),
	preload("res://art/rooms/ButtonRed.png"),
	preload("res://art/rooms/ButtonGreen.png"),
	preload("res://art/rooms/ButtonYellow.png"),
]

@onready var slots: Array = $Sequence.get_children()
@onready var type_label: Label = $StatusPanel/Symptom/TypeLabel

var sequence: Array = []   # the colours pressed so far

func _ready() -> void:
	super()
	$Buttons/Blue.pressed.connect(_press.bind(0))
	$Buttons/Red.pressed.connect(_press.bind(1))
	$Buttons/Green.pressed.connect(_press.bind(2))
	$Buttons/Yellow.pressed.connect(_press.bind(3))
	$ClearButton.pressed.connect(_clear)
	_clear()

func _press(color: int) -> void:
	if sequence.size() >= slots.size():
		return   # already full - CLEAR to start again
	sequence.append(color)
	_refresh_slots()

func _clear() -> void:
	sequence.clear()
	_refresh_slots()

func _refresh_slots() -> void:
	for i in slots.size():
		slots[i].texture = COLOR_TEXTURES[sequence[i]] if i < sequence.size() else null

func _read_controls() -> Array:
	return sequence

func _show_symptom(level: int) -> void:
	type_label.text = LEVEL_NAMES[level - 1] if level <= LEVEL_NAMES.size() else "TYPE %d" % level

func _on_wrong() -> void:
	_clear()

func _on_repaired() -> void:
	super()
	_clear()
