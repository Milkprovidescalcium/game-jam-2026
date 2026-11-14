extends Node2D

func move_scene(room_id: String) -> void:
	# Finds main Ship node and calls your backend function!
	var ship = get_tree().current_scene
	if ship.has_method("go_to"):
		ship.go_to(room_id)
	else:
		push_error("Could not find Ship root node!")

func _on_go_to_left_wing_button_pressed() -> void:
	move_scene("left_wing")

func _on_go_to_cockpit_button_pressed() -> void:
	move_scene("cockpit")

func _on_go_to_right_wing_pressed() -> void:
	move_scene("right_wing")

func _on_go_to_lower_engine_button_pressed() -> void:
	move_scene("lower_engine")
