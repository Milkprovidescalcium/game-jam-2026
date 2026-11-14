extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Ship sees: ", Network.numbers)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func move_scene(scene_name: String) -> void:
	print("meow meow meow meow")
	get_tree().change_scene_to_file(scene_name)
	


func _on_go_to_left_wing_button_pressed() -> void:
	print("I FUCKING HATEEE MY LIFE")
	move_scene("res://scenes/ship/LeftWing.tscn")
	pass # Replace with function body.
"res://scenes/ship/Cockpit.tscn"


func _on_go_to_cockpit_button_pressed() -> void:
	move_scene("res://scenes/ship/Cockpit.tscn")
	pass # Replace with function body.


func _on_go_to_right_wing_pressed() -> void:
	move_scene("res://scenes/ship/RightWing.tscn")
	pass # Replace with function body.


func _on_go_to_lower_engine_button_pressed() -> void:
	move_scene("res://scenes/ship/LowerEngine.tscn")
	pass # Replace with function body.
