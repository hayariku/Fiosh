extends Node2D

@export var fish_scene: PackedScene  # Drag and drop `Fish.tscn` here in the inspector
@export var number_of_fish: int = 5  # Number of fish to spawn
@export var spawn_area_size: Vector2 = Vector2(500, 500)  # The size of the spawning area

func _ready():
	# Spawn the specified number of fish
	for i in range(number_of_fish):
		spawn_fish()

func spawn_fish():
	# Ensure the `fish_scene` is assigned
	if not fish_scene:
		print("Error: No fish scene assigned!")
		return

	# Create an instance of the fish
	var fish = fish_scene.instantiate()

	# Set a random position within the spawn area
	var random_position = Vector2(
		randf_range(-spawn_area_size.x / 2, spawn_area_size.x / 2),
		randf_range(-spawn_area_size.y / 2, spawn_area_size.y / 2)
	)
	fish.position = global_position + random_position

	# Add the fish to the scene tree
	add_child(fish)
