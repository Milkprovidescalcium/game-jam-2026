extends TextureButton

## A clickable control that remembers its position: every click moves it one
## step on, and after the last position it wraps back to the first.
##   Knob:   choices = 4, step_degrees = 90    (up, right, down, left)
##   Switch: choices = 2, step_degrees = 180   (up, down)
## The manual on ground control draws its knobs and switches with the same
## rotations, so position 0 here looks like position 0 there.

signal value_changed(value: int)

@export var choices := 4          # how many positions it has
@export var step_degrees := 90.0  # how far it turns per click

var value := 0

func _ready() -> void:
	pivot_offset = size / 2       # turn around the centre, not the corner
	pressed.connect(func(): set_value(value + 1))
	set_value(value)

func set_value(new_value: int) -> void:
	value = posmod(new_value, choices)
	rotation_degrees = value * step_degrees
	value_changed.emit(value)
