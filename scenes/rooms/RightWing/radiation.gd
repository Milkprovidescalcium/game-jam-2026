extends PuzzleModule

const OK_COLOR := Color(0.15, 0.35, 0.2)
const BROKEN_COLOR := Color(0.7, 0.1, 0.1)

@onready var bg: ColorRect = $Background
@onready var name_label: Label = $NameLabel
@onready var status_label: Label = $StatusLabel
@onready var code_input: LineEdit = $CodeInput
@onready var fix_button: Button = $FixButton

func _ready() -> void:
	super()   # joins the "puzzle" group, don't remove
	name_label.text = "%s (%s)" % [puzzle_name, room_id]
	fix_button.pressed.connect(_try_fix)
	code_input.text_submitted.connect(func(_text): _try_fix())
	_show_ok()

# A random 3-digit code; ground control sees it on their map
func _generate_answer() -> Dictionary:
	return {"code": "%d%d%d" % [rng.randi_range(0, 9), rng.randi_range(0, 9), rng.randi_range(0, 9)]}

func _on_broken() -> void:
	bg.color = BROKEN_COLOR
	status_label.text = "⚠ SYSTEM FAILURE"
	code_input.editable = true
	fix_button.disabled = false

func _on_repaired() -> void:
	_show_ok()

func _show_ok() -> void:
	bg.color = OK_COLOR
	status_label.text = "OK"
	code_input.clear()
	code_input.editable = false
	fix_button.disabled = true

func _try_fix() -> void:
	if not is_broken:
		return
	if code_input.text.strip_edges() == answer.code:
		repair()
	else:
		fail_attempt()   # costs health
		status_label.text = "✗ WRONG CODE"
	code_input.clear()
