class_name PuzzleModule
extends Node2D   # change to Control if your puzzles are built from UI nodes

## Base class for every puzzle. A puzzle lives under Ship/Puzzles the whole
## round (so it can break while the player is somewhere else) and stays hidden
## until the room's PuzzleButton opens it:
##   ship.open_puzzle()    # shows the puzzle of the room the player is in
##   ship.close_puzzle()   # hides it again (also happens when the player moves)
## Give the scene a Button called "CloseButton" and it closes the puzzle for you.

signal broken_changed(module: PuzzleModule, is_broken: bool)
signal failed(module: PuzzleModule)
signal opened(module: PuzzleModule)
signal closed(module: PuzzleModule)

@export var room_id: String = ""       # e.g. "cockpit" - must match a room in ship.gd
@export var puzzle_name: String = ""   # e.g. "Dropping Parts"

var is_broken := false
var is_open := false
var answer: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("puzzle")
	hide()   # hidden puzzles ignore clicks but keep running
	var close_button := get_node_or_null("CloseButton") as BaseButton
	if close_button:
		close_button.pressed.connect(close)

# Called once by the GameManager at round start
func setup(seed_value: int) -> void:
	rng.seed = seed_value

# ---- Showing / hiding (the Ship calls these) ----
func open() -> void:
	if is_open:
		return
	is_open = true
	show()
	_on_opened()
	opened.emit(self)

func close() -> void:
	if not is_open:
		return
	is_open = false
	hide()
	_on_closed()
	closed.emit(self)

# ---- Breaking / fixing ----
func break_module() -> void:
	if is_broken:
		return
	is_broken = true
	answer = _generate_answer()   # new answer every time it breaks
	_on_broken()
	broken_changed.emit(self, true)

# Puzzles call this when the player gets it right
func repair() -> void:
	if not is_broken:
		return
	is_broken = false
	_on_repaired()
	broken_changed.emit(self, false)

# Puzzles call this when the player gets it wrong
func fail_attempt() -> void:
	failed.emit(self)

# ---- Each puzzle overrides these ----
func _generate_answer() -> Dictionary:
	return {}

func _on_broken() -> void:
	pass   # alarms, effects, show the puzzle

func _on_repaired() -> void:
	pass   # stop effects

func _on_opened() -> void:
	pass   # the player just opened this puzzle

func _on_closed() -> void:
	pass   # the player closed it or left the room
