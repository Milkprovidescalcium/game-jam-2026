extends Node2D

@onready var sprite: Sprite2D = $ParentTexture/Instructions
@onready var bottom_border: Sprite2D = $BottomOfCamSprite
@onready var top_border: Sprite2D = $TopOfCamSprite

@onready var parent: Sprite2D = $ParentTexture

@onready var knobs: Node2D = $ParentTexture/Knobs
@onready var switches: Node2D = $ParentTexture/Switches
@onready var radiation: Node2D = $ParentTexture/Radiaton
@onready var coords: Node2D = $ParentTexture/Coords


@onready var canvas: CanvasLayer = $CanvasLayer


@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()

var paper_sound = preload("res://audio/sfx/picking up paper.mp3")
var paper_putdown = preload("res://audio/sfx/paper put down(2).mp3")


func play_paper_sound() -> void:
	audio_player.stream = paper_sound
	audio_player.play(0.2) #idk why its 0.2 just dont change
	
func play_paper_putdown() -> void:
	audio_player.stream = paper_putdown
	audio_player.play(0.2)


func _ready() -> void:
	#makes all the sprite's y value get like pivoted to the bottom instead of the middle
	sprite.position = Vector2.ZERO
	sprite.offset.y = -sprite.texture.get_height() / 2.0
	bottom_border.offset.y = -bottom_border.texture.get_height() / 2.0
	top_border.offset.y = -top_border.texture.get_height() / 2.
	
	parent.position.y = ORIGINY
	parent.position.x = ORIGINX
	
	knobs.hide()
	switches.hide()
	radiation.hide()
	coords.hide()
	
	add_child(audio_player)
	
	ShipNet.manual_received.connect(apply_manual)
	if not ShipNet.manual.is_empty():
		apply_manual(ShipNet.manual)
		
func apply_manual(manual: Dictionary) -> void:
	var vents: Array = manual.get("left_wing", [])        # 3 levels x 3 knobs
	for lvl in vents.size():
		for i in vents[lvl].size():
			knobs.get_child(lvl * vents[lvl].size() + i).rotation_degrees = vents[lvl][i] * 90

	var rad: Array = manual.get("right_wing", [])         # 3 levels x 4 sprites
	for lvl in rad.size():
		for i in rad[lvl].size():
			radiation.get_child(lvl * rad[lvl].size() + i).texture = radiation_textures[rad[lvl][i]]

	var temp: Array = manual.get("lower_engine", [])      # 4 levels x 5 switches
	for lvl in temp.size():
		for i in temp[lvl].size():
			switches.get_child(lvl * temp[lvl].size() + i).rotation_degrees = temp[lvl][i] * 180

	var land: Array = manual.get("cockpit", [])           # 1 level: [x, y]
	if not land.is_empty():
		coords.get_child(0).text = str(land[0][0])
		coords.get_child(1).text = str(land[0][1])

var ORIGINX = 190
var ORIGINY = 9999

var ONSCREENX = 190
var ONSCREENY = 1800
var TWEENSPEED = 0.5
var onScreen = false;



var rng := RandomNumberGenerator.new()

# put your 4 radiation sprites here (fix the paths to your files)
var radiation_textures: Array[Texture2D] = [
	preload("res://art/rooms/ButtonBlue.png"),
	preload("res://art/rooms/ButtonRed.png"),
	preload("res://art/rooms/ButtonGreen.png"),
	preload("res://art/rooms/ButtonYellow.png"),

]

func randomize_from_seed(game_seed: int) -> void:
	rng.seed = game_seed

	# knobs: 0, 90, 180, or 270 degrees
	for knob in knobs.get_children():
		knob.rotation_degrees = rng.randi_range(0, 3) * 90

	# switches: 0 or 180 degrees
	for sw in switches.get_children():
		sw.rotation_degrees = rng.randi_range(0, 1) * 180

	# radiation: one of 4 textures each
	for rad in radiation.get_children():
		rad.texture = radiation_textures[rng.randi_range(0, 3)]
	
		# radiation: one of 4 textures each
	for cord in coords.get_children():
		cord.text = str(rng.randi_range(100, 275))


func move_to_screen() -> void: 
	play_paper_sound()
	
	print("sprite moved")
	var tween := create_tween()
	tween.tween_property(parent, "position", Vector2(ONSCREENX, ONSCREENY), TWEENSPEED)
	
	onScreen = true;
	canvas.hide()
	print(sprite.position)


func move_down() -> void:
	play_paper_putdown()
	print("moved down")
	var tween := create_tween()
	tween.tween_property(parent, "position", Vector2(ORIGINX, ORIGINY), TWEENSPEED)
	tween.tween_callback(_hide_overlays)
	
	onScreen = false
	canvas.show()
	
func _hide_overlays() -> void:
	knobs.hide()
	switches.hide()
	radiation.hide()
	coords.hide()
		

var scroll_speed = 50
func _sprite_top() -> float: #calculates the top of the sprite
	return parent.global_position.y - sprite.texture.get_height() * sprite.global_scale.y
	
func _apply_offset() -> void:
	sprite.offset.y = -sprite.texture.get_height() / 2.0
	knobs.position = Vector2(0, sprite.offset.y * sprite.scale.y)
	switches.position = Vector2(0, sprite.offset.y * sprite.scale.y)
	radiation.position = Vector2(0, sprite.offset.y * sprite.scale.y)
	coords.position = Vector2(0, sprite.offset.y * sprite.scale.y)
	
	
	

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton and event.pressed and onScreen:
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if parent.global_position.y - scroll_speed >= bottom_border.global_position.y:
				parent.position.y -= scroll_speed
				
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if(_sprite_top() - scroll_speed <= top_border.global_position.y):
				parent.position.y += scroll_speed  

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		move_down()

#hardcoded stretched values. pls do not touch

func _on_button_pressed() -> void:
	
	if not onScreen:
		print("drop part")
		sprite.texture = load("res://art/rooms/landing 101new(1).png")
		sprite.scale = Vector2(0.41, 0.36)
		coords.show()
		coords.scale = Vector2(0.41, 0.36)
		_apply_offset()
		move_to_screen()
	
	pass # Replace with function body.

func _on_oxygen_button_pressed() -> void:
	
	if not onScreen:
		print("oxygen")
		sprite.texture = load("res://art/rooms/oxygen2.png")
		sprite.scale = Vector2(0.41, 0.36)
		knobs.show()
		knobs.scale = Vector2(0.41, 0.36)
		
		_apply_offset()
		move_to_screen()
		
	
	pass # Replace with function body.


func _on_thermal_button_pressed() -> void:
	
	if not onScreen:
		print("thermal")
		sprite.texture = load("res://art/rooms/Temperature Guide.jpg")
		sprite.scale = Vector2(0.37, 0.36)
		switches.show()
		switches.scale = Vector2(0.37, 0.36)
	
		_apply_offset()
		move_to_screen()
	
	pass # Replace with function body.


func _on_radiation_button_pressed() -> void:
	
	if not onScreen:
		print("radiation")
		sprite.texture = load("res://art/rooms/Radiation Page.jpg")
		sprite.scale = Vector2(0.41, 0.36)
		radiation.show()
		radiation.scale = Vector2(0.41, 0.36)

		_apply_offset()
		
		move_to_screen()
	
	pass # Replace with function body.


func _on_checklist_node_checklist_down() -> void:
	canvas.show()
	pass # Replace with function body.


func _on_checklist_node_checklist_up() -> void:
	canvas.hide()
	pass # Replace with function body.
