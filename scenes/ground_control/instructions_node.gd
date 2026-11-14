extends Node2D

@onready var sprite: Sprite2D = $Instructions
@onready var bottom_border: Sprite2D = $BottomOfCamSprite
@onready var top_border: Sprite2D = $TopOfCamSprite


func _ready() -> void:
	#makes all the sprite's y value get like pivoted to the bottom instead of the middle
	sprite.offset.y = -sprite.texture.get_height() / 2.0
	bottom_border.offset.y = -bottom_border.texture.get_height() / 2.0
	top_border.offset.y = -top_border.texture.get_height() / 2.0
	

var ORIGINX = 190
var ORIGINY = 3800

var ONSCREENX = 190
var ONSCREENY = 1500
var TWEENSPEED = 0.25
var onScreen = false;


func move_to_screen() -> void: 
	print("sprite moved")
	var tween := create_tween()
	tween.tween_property(sprite, "position", Vector2(ONSCREENX, ONSCREENY), TWEENSPEED)
	
	onScreen = true;
	print(sprite.position)
func move_down() -> void:
	print("moved down")
	var tween := create_tween()
	tween.tween_property(sprite, "position", Vector2(ORIGINX, ORIGINY), TWEENSPEED)
	
	onScreen = false

var scroll_speed = 50
func _sprite_top() -> float: #calculates the top of the sprite
	return sprite.global_position.y - sprite.texture.get_height() * sprite.global_scale.y

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton and event.pressed and onScreen:
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if sprite.global_position.y - scroll_speed >= bottom_border.global_position.y:
				sprite.position.y -= scroll_speed
				
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if(_sprite_top() - scroll_speed <= top_border.global_position.y):
				sprite.position.y += scroll_speed  

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
		sprite.texture = load("res://art/rooms/landing 101.jpg")
		sprite.scale = Vector2(0.41, 0.36)
		sprite.offset.y = -sprite.texture.get_height() / 2.0
		move_to_screen()
	
	pass # Replace with function body.

func _on_oxygen_button_pressed() -> void:
	
	if not onScreen:
		print("oxygen")
		sprite.texture = load("res://art/rooms/oxygen2.png")
		sprite.scale = Vector2(0.41, 0.36)
		sprite.offset.y = -sprite.texture.get_height() / 2.0
		move_to_screen()
		
	
	pass # Replace with function body.


func _on_thermal_button_pressed() -> void:
	
	if not onScreen:
		print("thermal")
		sprite.texture = load("res://art/rooms/Temperature Guide.jpg")
		sprite.scale = Vector2(0.37, 0.36)
		sprite.offset.y = -sprite.texture.get_height() / 2.0
		move_to_screen()
	
	pass # Replace with function body.


func _on_radiation_button_pressed() -> void:
	
	if not onScreen:
		print("radiation")
		sprite.texture = load("res://art/rooms/Radiation Page.jpg")
		sprite.scale = Vector2(0.41, 0.36)
		sprite.offset.y = -sprite.texture.get_height() / 2.0
		move_to_screen()
	
	pass # Replace with function body.
