class_name PuzzleModule
extends Node2D   # change to Control if your puzzles are built from UI nodes

signal broken_changed(module: PuzzleModule, is_broken: bool)
signal failed(module: PuzzleModule)

@export var room_id: String = ""       # e.g. "cockpit"
@export var puzzle_name: String = ""   # e.g. "Dropping Parts"

var is_broken := false
var answer: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("puzzle")

# Called once by the GameManager at round start
func setup(seed_value: int) -> void:
	rng.seed = seed_value

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
