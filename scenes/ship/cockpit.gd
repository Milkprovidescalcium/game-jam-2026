extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func move_scene(room_id: String) -> void:
	# Finds your main Ship node and calls your backend function!
	var ship = get_tree().current_scene
	if ship.has_method("go_to"):
		ship.go_to(room_id)
	else:
		push_error("Could not find Ship root node!")
	
	
func _on_go_to_body_pressed() -> void:
	move_scene("body")
	pass # Replace with function body.


func _on_puzzle_button_pressed() -> void:
	pass # Replace with function body.
