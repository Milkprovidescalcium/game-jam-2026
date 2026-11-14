extends Node2D

## Player 1 (the ship). Room logic only - no UI here, so the front end can
## build its own navigation on top of it:
##   ship.go_to("cockpit")            # move the player (only to a connected room)
##   ship.can_move_to("left_wing")    # true if that room is next to the current one
##   ship.room_changed.connect(...)   # react when the player moves
##   ship.current_room / ROOM_NAMES / CONNECTIONS
##
## Puzzles: every PuzzleModule under $Puzzles is matched to a room by its
## room_id. A room that has a "UI/PuzzleButton" gets it wired up automatically:
##   ship.open_puzzle()               # open the puzzle of the current room
##   ship.close_puzzle()              # close it (Esc, the BACK button, or moving)
##   ship.puzzle_opened / puzzle_closed

signal room_changed(room_id: String)
signal puzzle_opened(room_id: String)
signal puzzle_closed(room_id: String)

const ROOM_NAMES := {
	"body": "Main Body",
	"cockpit": "Cockpit",
	"left_wing": "Left Wing",
	"right_wing": "Right Wing",
	"lower_engine": "Lower Engine",
}

# Which rooms you can walk to from each room (the body is the hub)
const CONNECTIONS := {
	"body": ["cockpit", "left_wing", "right_wing", "lower_engine"],
	"cockpit": ["body"],
	"left_wing": ["body"],
	"right_wing": ["body"],
	"lower_engine": ["body"],
}

@onready var rooms := {
	"body": $Rooms/Body,
	"cockpit": $Rooms/Cockpit,
	"left_wing": $Rooms/LeftWing,
	"right_wing": $Rooms/RightWing,
	"lower_engine": $Rooms/LowerEngine,
}

var current_room := "body"
var puzzles := {}                      # room_id -> PuzzleModule
var open_puzzle_module: PuzzleModule   # null while no puzzle is on screen

func _ready() -> void:
	_register_puzzles()
	Network.player_disconnected.connect(_on_ground_left)
	# Re-send our position when the round starts (ground control is listening by then)
	ShipNet.game_started.connect(func(_seed): _enter("body"))
	_enter("body")

# Ground control quit or lost connection: the game is over for us too
func _on_ground_left(_peer_id: int) -> void:
	Network.end_session("Ground Control disconnected - game over.")

func can_move_to(room_id: String) -> bool:
	return room_id in CONNECTIONS.get(current_room, [])

## Move to a connected room. Returns false if the move isn't allowed.
func go_to(room_id: String) -> bool:
	if not can_move_to(room_id):
		push_warning("Can't move from '%s' to '%s'" % [current_room, room_id])
		return false
	_enter(room_id)
	return true

func _enter(room_id: String) -> void:
	close_puzzle()
	current_room = room_id
	for id in rooms:
		rooms[id].visible = (id == room_id)   # hidden rooms also ignore clicks
		_set_room_ui_visible(id, id == room_id)
	ShipNet.report_player_room(room_id)       # moves the marker on ground control's map
	room_changed.emit(room_id)

# ---------- Puzzles ----------

## Open the puzzle of the room the player is standing in.
## Returns false if that room has no puzzle.
func open_puzzle() -> bool:
	var module: PuzzleModule = puzzles.get(current_room)
	if module == null:
		push_warning("Room '%s' has no puzzle" % current_room)
		return false
	if open_puzzle_module == module:
		return true
	close_puzzle()
	open_puzzle_module = module
	_set_room_ui_visible(current_room, false)   # the room's button would sit on top of the puzzle
	module.open()
	puzzle_opened.emit(current_room)
	return true

func close_puzzle() -> void:
	if open_puzzle_module:
		open_puzzle_module.close()   # comes back through _on_puzzle_closed

func _register_puzzles() -> void:
	$Puzzles.z_index = 100   # always drawn above the room art and arrows
	for node in $Puzzles.get_children():
		var module := node as PuzzleModule
		if module == null:
			continue
		if not rooms.has(module.room_id):
			push_warning("Puzzle '%s' has an unknown room_id '%s'" % [module.name, module.room_id])
			continue
		if puzzles.has(module.room_id):
			push_warning("Room '%s' has two puzzles - '%s' is ignored" % [module.room_id, module.name])
			continue
		puzzles[module.room_id] = module
		module.position = Vector2.ZERO   # puzzles are laid out for the full screen
		module.closed.connect(_on_puzzle_closed)
	for id in rooms:
		var button := rooms[id].get_node_or_null("UI/PuzzleButton") as BaseButton
		if button:
			button.visible = puzzles.has(id)
			button.pressed.connect(open_puzzle)

func _on_puzzle_closed(module: PuzzleModule) -> void:
	if module != open_puzzle_module:
		return
	open_puzzle_module = null
	_set_room_ui_visible(current_room, true)
	puzzle_closed.emit(module.room_id)

# A room's "UI" CanvasLayer does NOT hide with the room, so show/hide it by hand
func _set_room_ui_visible(room_id: String, shown: bool) -> void:
	var ui := rooms[room_id].get_node_or_null("UI") as CanvasLayer
	if ui:
		ui.visible = shown

func _unhandled_input(event: InputEvent) -> void:
	if open_puzzle_module and event.is_action_pressed("ui_cancel"):
		close_puzzle()
		get_viewport().set_input_as_handled()
