extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$dialogue.current_name_index = 2
	$dialogue.update_name()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
