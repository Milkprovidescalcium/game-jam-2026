extends Node2D


signal show_papers

@onready var button: Button = $PapersSprite/PapersButton 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(func(): show_papers.emit())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	print("farty")
	pass # Replace with function body.
