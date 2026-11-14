extends Control

const OK_COLOR := Color(0.15, 0.35, 0.2)      # dark green = working
const BROKEN_COLOR := Color(0.85, 0.1, 0.1)   # red = broken
const DIM_RED := Color(0.35, 0.05, 0.05)

@onready var rooms := {
	"body": %Body,
	"cockpit": %Cockpit,
	"left_wing": %LeftWing,
	"right_wing": %RightWing,
	"lower_engine": %LowerEngine,
}
@onready var marker: ColorRect = %PlayerMarker
@onready var info_label: RichTextLabel = %InfoLabel

var broken := {}    # room_id -> true while broken
var answers := {}   # room_id -> info Dictionary
var flashes := {}   # room_id -> Tween

func _ready() -> void:
	for id in rooms:   # write the room names on the map
		var label := rooms[id].get_node_or_null("Label") as Label
		if label:
			label.text = id.replace("_", " ").to_upper()
			label.add_theme_font_size_override("font_size", 26)   # fits "LOWER ENGINE" in the box
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.z_index = 1   # draw the player on top of every room
	marker.color = Color(1.0, 0.85, 0.2)
	ShipNet.room_status_changed.connect(_on_room_status)
	ShipNet.player_moved.connect(_on_player_moved)
	ShipNet.puzzle_info.connect(_on_puzzle_info)
	ShipNet.game_started.connect(func(_seed): _reset())
	_reset()

func _reset() -> void:
	for id in rooms:
		_stop_flash(id)
		rooms[id].color = OK_COLOR
	broken.clear()
	answers.clear()
	_refresh_info()

# ---------- Room broken / fixed ----------

func _on_room_status(room_id: String, is_broken: bool) -> void:
	if not rooms.has(room_id):
		push_warning("Map has no room called '%s'" % room_id)
		return
	if is_broken:
		broken[room_id] = true
		_start_flash(room_id)
	else:
		broken.erase(room_id)
		answers.erase(room_id)
		_stop_flash(room_id)
		rooms[room_id].color = OK_COLOR
	_refresh_info()

func _start_flash(room_id: String) -> void:
	_stop_flash(room_id)
	var rect: ColorRect = rooms[room_id]
	var tween := create_tween().set_loops()
	tween.tween_property(rect, "color", BROKEN_COLOR, 0.4)
	tween.tween_property(rect, "color", DIM_RED, 0.4)
	flashes[room_id] = tween

func _stop_flash(room_id: String) -> void:
	if flashes.has(room_id):
		flashes[room_id].kill()
		flashes.erase(room_id)

# ---------- Where player 1 is ----------

func _on_player_moved(room_id: String) -> void:
	if not rooms.has(room_id):
		return
	var rect: ColorRect = rooms[room_id]
	var target := rect.position + rect.size / 2 - marker.size / 2
	create_tween().tween_property(marker, "position", target, 0.2)

# ---------- What's broken + how to fix it ----------

func _on_puzzle_info(room_id: String, info: Dictionary) -> void:
	answers[room_id] = info
	_refresh_info()

func _refresh_info() -> void:
	if broken.is_empty():
		info_label.text = "[color=green]ALL SYSTEMS NOMINAL[/color]"
		return
	var text := ""
	for room_id in broken:
		var room_name: String = room_id.replace("_", " ").to_upper()
		var info: Dictionary = answers.get(room_id, {})
		text += "[color=red]!! %s - %s[/color]\n" % [room_name, info.get("puzzle", "Unknown failure")]
		for key in info:
			if key != "puzzle":
				text += "    %s: [b]%s[/b]\n" % [key, str(info[key])]
		text += "\n"
	info_label.text = text
