extends PuzzleModule

## Temperature puzzle (Lower Engine).
## Placeholder mechanic: ground control reads a 3-digit code off their map and
## the ship player types it in. Swap _generate_answer() / _try_fix() for the
## real puzzle - everything else (breaking, health, opening, closing) is
## handled by PuzzleModule, GameManager and Ship.

const OK_COLOR := Color(0.15, 0.35, 0.2)
const BROKEN_COLOR := Color(0.7, 0.1, 0.1)
const OK_HINT := "All systems nominal. Nothing to repair here."
const BROKEN_HINT := "Ask Ground Control for the 3-digit repair code, type it in and press REPAIR."
const WRONG_HINT := "Wrong code - the ship took damage. Check with Ground Control and try again."

@onready var status_panel: ColorRect = $StatusPanel
@onready var name_label: Label = $StatusPanel/NameLabel
@onready var status_label: Label = $StatusPanel/StatusLabel
@onready var hint_label: Label = $StatusPanel/HintLabel
@onready var code_input: LineEdit = $CodeInput
@onready var fix_button: Button = $FixButton

func _ready() -> void:
	super()   # joins the "puzzle" group and hides the puzzle, don't remove
	name_label.text = puzzle_name.to_upper()
	fix_button.pressed.connect(_try_fix)
	code_input.text_submitted.connect(func(_text): _try_fix())
	_show_ok()

func _generate_answer() -> Dictionary:
	var index := rng.randi_range(0, rules.size() - 1)
	return {"level": index + 1, "solution": rules[index]}

func _on_broken() -> void:
	status_panel.color = BROKEN_COLOR
	status_label.text = "SYSTEM FAILURE"
	hint_label.text = BROKEN_HINT
	code_input.editable = true
	fix_button.disabled = false

func _on_repaired() -> void:
	_show_ok()

func _on_closed() -> void:
	code_input.clear()   # don't keep a half-typed code around

func _show_ok() -> void:
	status_panel.color = OK_COLOR
	status_label.text = "OK"
	hint_label.text = OK_HINT
	code_input.clear()
	code_input.editable = false
	fix_button.disabled = true

func _try_fix() -> void:
	if not is_broken:
		return
	var wanted := ""
	for value in answer.solution:
		wanted += str(value)
	if code_input.text.strip_edges().replace(" ", "") == wanted:
		repair()
	else:
		fail_attempt()
		status_label.text = "WRONG CODE"
		hint_label.text = WRONG_HINT
	code_input.clear()
