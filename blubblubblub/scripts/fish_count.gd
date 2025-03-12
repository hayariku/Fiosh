extends Control
@onready var main = get_parent()

var main_count = "0"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Panel.modulate.a = 0.0
	if main and "caught_fish" in main:
		main_count = main.caught_fish.size()

func _on_fishing_fish_count_update() -> void:
	main_count = main.caught_fish.size()
	$Panel/Label.text = main_count
