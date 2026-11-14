extends Node2D

## Player 1 (the ship). Room logic only - no UI here, so the front end can
## build its own navigation on top of it:
##   ship.go_to("cockpit")            # move the player (only to a connected room)
##   ship.can_move_to("left_wing")    # true if that room is next to the current one
##   ship.room_changed.connect(...)   # react when the player moves
##   ship.current_room / ROOM_NAMES / CONNECTIONS

signal room_changed(room_id: String)

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

func _ready() -> void:
	# Re-send our position when the round starts (ground control is listening by then)
	ShipNet.game_started.connect(func(_seed): _enter("body"))
	_enter("body")

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
	current_room = room_id
	for id in rooms:
		rooms[id].visible = (id == room_id)   # hidden rooms also ignore clicks
	ShipNet.report_player_room(room_id)       # moves the marker on ground control's map
	room_changed.emit(room_id)
