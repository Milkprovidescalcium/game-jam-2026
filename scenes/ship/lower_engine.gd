extends Node2D



func _ready() -> void:
	add_child(audio_player)
	audio_player.stream = button_sound

@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
var button_sound = preload("res://audio/sfx/change area.mp3")

func play_sound() -> void:
	audio_player.stream = button_sound
	audio_player.play(0.2) #idk why its 0.2 just dont change

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
	play_sound()
	move_scene("body")
	pass # Replace with function body.
