extends PuzzleModule

## Shared behaviour for the four control-panel puzzles (Ventilation,
## Temperature, Radiation, Landing). The GameManager gives each puzzle its rules
## from the manual; when the system breaks one rule becomes the answer, the
## panel shows which one ("level") and the player sets the controls to match
## what Ground Control reads out of their manual, then presses REPAIR.
##
## A puzzle only has to say how to read its controls and how to show the level:
##   _read_controls()       -> Array of ints, same shape as one rule
##   _show_symptom(level)   -> light up the gauge / name the level

const OK_COLOR := Color(0.15, 0.35, 0.2)
const BROKEN_COLOR := Color(0.7, 0.1, 0.1)
const SEGMENT_OFF := Color(0, 0, 0, 0.45)
const ALERT_SCREEN: Texture2D = preload("res://art/red screen.png")   # shown while the system is broken
const OK_HINT := "All systems nominal. Nothing to repair here."
const WRONG_HINT := "Wrong settings - the ship took damage. Check with Ground Control and try again."

@export_multiline var broken_hint := "Set the controls the way Ground Control tells you, then press REPAIR."

@onready var status_panel: Control = $StatusPanel   # the screen behind the status text
@onready var name_label: Label = $StatusPanel/NameLabel
@onready var status_label: Label = $StatusPanel/StatusLabel
@onready var hint_label: Label = $StatusPanel/HintLabel
@onready var symptom: Control = get_node_or_null("StatusPanel/Symptom")
@onready var fix_button: Button = $FixButton

var _normal_screen: Texture2D   # whatever the scene gives StatusPanel (the blue screen)

func _ready() -> void:
	super()   # joins the "puzzle" group and hides the puzzle, don't remove
	if status_panel is TextureRect:
		_normal_screen = status_panel.texture
	name_label.text = puzzle_name.to_upper()
	fix_button.pressed.connect(_try_fix)
	_show_ok()

# One of this system's rules becomes the answer each time it breaks
func _generate_answer() -> Dictionary:
	if rules.is_empty():
		push_warning("%s has no rules - is its room_id in MANUAL_SPEC?" % puzzle_name)
		return {"level": 1, "solution": []}
	var index := rng.randi_range(0, rules.size() - 1)
	return {"level": index + 1, "solution": rules[index]}

func _on_broken() -> void:
	_set_alert(true)
	status_label.text = "SYSTEM FAILURE"
	hint_label.text = broken_hint
	fix_button.disabled = false
	if symptom:
		symptom.show()
	_show_symptom(answer.level)

func _on_repaired() -> void:
	_show_ok()

func _show_ok() -> void:
	_set_alert(false)
	status_label.text = "OK"
	hint_label.text = OK_HINT
	fix_button.disabled = true
	if symptom:
		symptom.hide()

func _try_fix() -> void:
	if not is_broken:
		return
	if _read_controls() == answer.solution:
		repair()
	else:
		fail_attempt()   # costs health
		status_label.text = "WRONG SETTINGS"
		hint_label.text = WRONG_HINT
		_on_wrong()

# Emergency: the blue screen turns red until the system is repaired.
# (A plain ColorRect panel still works: it changes colour instead.)
func _set_alert(on: bool) -> void:
	if status_panel is TextureRect:
		status_panel.texture = ALERT_SCREEN if on else _normal_screen
	elif status_panel is ColorRect:
		status_panel.color = BROKEN_COLOR if on else OK_COLOR

# Colour the first `count` ColorRects under `container`, dim the rest
func _light_segments(container: Node, count: int, on_color: Color) -> void:
	var index := 0
	for child in container.get_children():
		var segment := child as ColorRect
		if segment:
			segment.color = on_color if index < count else SEGMENT_OFF
			index += 1

# ---- Each puzzle overrides these ----
func _read_controls() -> Array:
	return []   # the values the player has set, e.g. [0, 3, 1]

func _show_symptom(_level: int) -> void:
	pass   # show the player which level broke (1 = the first rule in the manual)

func _on_wrong() -> void:
	pass   # e.g. clear what the player entered
