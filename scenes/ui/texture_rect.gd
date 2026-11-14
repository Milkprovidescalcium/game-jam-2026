extends TextureRect

const WIN_TEX = preload("res://art/ui/lose_screen.png")
const LOSE_TEX = preload("res://art/ui/lose_screen.png") # Verify if this is in art/ or art/ui/

func _ready() -> void:
	hide() # Hides the TextureRect when the game starts
	ShipNet.game_ended.connect(_on_game_ended)

func _on_game_ended(won: bool) -> void:
	texture = WIN_TEX if won else LOSE_TEX
	show() # Makes the TextureRect visible when the game ends
