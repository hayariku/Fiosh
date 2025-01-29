extends Node2D

@export var fish_scene: PackedScene  # Assign `Fish.tscn` in the Inspector
@export var max_fish: int = 20  # Keep exactly 20 fish in the scene
@export var spawn_distance_range: Vector2 = Vector2(2500, 4500)  # Distance away from the player
@export var spawn_depth_range: Vector2 = Vector2(700, 1200)  # Ensure fish spawn at correct depth

var fish_list = []  

func _ready():
	# Ensure we start with exactly `max_fish` fish
	for i in range(max_fish):
		spawn_fish()

	# Run a check every second to maintain count
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.0  # Check every second
	spawn_timer.autostart = true
	spawn_timer.connect("timeout", Callable(self, "_check_fish_count"))
	add_child(spawn_timer)

func _check_fish_count():
	# If fish count drops below `max_fish`, spawn new ones
	while fish_list.size() < max_fish:
		spawn_fish()

func spawn_fish():
	if not fish_scene:
		print("[ERROR] No fish scene assigned!")
		return

	var fish = fish_scene.instantiate()

	# Generate spawn location based on rules
	var spawn_distance = randf_range(spawn_distance_range.x, spawn_distance_range.y)
	var spawn_y = randf_range(spawn_depth_range.x, spawn_depth_range.y)

	# Randomly choose whether to spawn left or right
	var spawn_x = spawn_distance if randi() % 2 == 0 else -spawn_distance

	# Set spawn position
	fish.global_position = Vector2(spawn_x, spawn_y)

	# Track despawning properly
	fish.connect("tree_exited", Callable(self, "_on_fish_despawned").bind(fish))

	add_child(fish)
	fish_list.append(fish)

	print("[DEBUG] Spawned fish at:", fish.global_position)
	print("[DEBUG] Current fish count:", fish_list.size())

# Called when a fish is removed from the game
func _on_fish_despawned(fish):
	if fish_list.has(fish):
		fish_list.erase(fish)

	print("[DEBUG] Fish despawned. Current fish count:", fish_list.size())

	# Trigger a check to refill the fish
	_check_fish_count()
