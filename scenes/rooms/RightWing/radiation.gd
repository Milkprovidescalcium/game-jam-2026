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
	add_child(audio_player)
	audio_player.stream = button_sound
	audio_player.volume_db += 20.0 # Adds 5 decibels
	super()
	$Buttons/Blue.pressed.connect(_press.bind(0))
	$Buttons/Red.pressed.connect(_press.bind(1))
	$Buttons/Green.pressed.connect(_press.bind(2))
	$Buttons/Yellow.pressed.connect(_press.bind(3))
	$ClearButton.pressed.connect(_clear)
	_clear()
	
@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
var button_sound = preload("res://audio/sfx/light_switch.mp3")


func play_sound() -> void:
	audio_player.stream = button_sound
	audio_player.play(0.2) #idk why its 0.2 just dont change

func _press(color: int) -> void:
	play_sound()
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
