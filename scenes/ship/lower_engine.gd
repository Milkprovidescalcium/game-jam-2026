extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func move_scene(scene_name: String) -> void:
	print("meow meow meow meow")
	get_tree().change_scene_to_file(scene_name)
	
	
func _on_go_to_body_pressed() -> void:
	print("I FUCKING HATEEE MY LIFE")
	move_scene("res://scenes/ship/Body.tscn")
	pass # Replace with function body.
