extends Node2D

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
