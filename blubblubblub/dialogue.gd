extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	handle_input(delta)
	
func handle_input(delta):
	if Input.is_action_just_pressed("n"):
		queue_free()
