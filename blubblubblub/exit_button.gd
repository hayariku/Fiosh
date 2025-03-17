extends Button

@onready var exit_button: Button = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate.a = 0
	exit_button.pressed.connect(_on_next_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.

func _on_next_button_pressed():
	get_tree().change_scene_to_file("res://2FishermanMain.tscn")
func _process(delta):
	if Input.is_action_just_released("Escape"):
		get_tree().change_scene_to_file("res://2FishermanMain.tscn")
