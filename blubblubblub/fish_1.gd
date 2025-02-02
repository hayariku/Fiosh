extends CharacterBody2D

# Fish behavior variables
@export var move_speed: float = 100.0
@export var detection_radius: float = 200.0  # Larger radius for testing
@export var angle_change_interval: float = 2.0  # Time interval (seconds) to change direction

# Weight impacts fish size in-game
@export var weight: float = 1.0  # We'll randomize this in _ready()

# States
var is_aggro: bool = false
var direction: Vector2 = Vector2.ZERO
var hook: Node2D
var angle_timer: Timer
var is_caught: bool = false  # Tracks if this fish is caught

const DESPAWN_BOUNDARY = 5000  # Fish despawn if they exceed this limit

func _ready():
	randomize()
	# Randomize the fish's weight
	weight = randf_range(1, 5.0)
	
	# Spawn the fish within x: 0..5200, y: 700..1200
	global_position = Vector2(
		randf_range(0, 5200),
		randf_range(700, 1200)
	)

	# Adjust the fish's scale based on its randomized weight
	scale = Vector2.ONE * weight  

	# Reference the hook node (adjust the path as necessary)
	hook = get_parent().get_node("Hook")

	# Set up initial direction and timer for angle change
	set_random_angle()
	angle_timer = Timer.new()
	angle_timer.wait_time = angle_change_interval
	angle_timer.one_shot = false
	add_child(angle_timer)
	angle_timer.start()
	angle_timer.connect("timeout", Callable(self, "_on_angle_change_timer_timeout"))

	# Connect Area2D's body_entered signal for catching
	var area = $Area2D
	area.connect("body_entered", Callable(self, "_on_area_entered"))

func _physics_process(delta):
	if is_caught:
		# Snap to the hook's position and stop movement
		global_position = hook.global_position + Vector2(0, 10)
		velocity = Vector2.ZERO
	elif is_aggro:
		detect_and_move_to_hook()
	else:
		velocity = direction * move_speed
		move_and_slide()

	# Despawn if the fish is beyond the 5000 pixel range
	if abs(global_position.x) > DESPAWN_BOUNDARY or abs(global_position.y) > DESPAWN_BOUNDARY:
		print("[DEBUG] Fish at", global_position, "despawned due to boundary limits.")

		# Notify the fish spawner before removing the fish
		var spawner = get_parent()
		if spawner and spawner.has_method("on_fish_despawned"):
			spawner.on_fish_despawned(self)

		queue_free()

func detect_and_move_to_hook():
	if hook.global_position.distance_to(global_position) <= detection_radius:
		# Turn toward the hook
		direction = (hook.global_position - global_position).normalized()

func _on_area_entered(body):
	# Check if the hook entered the fish's Area2D and ensure only one fish can be caught
	if body == hook and not is_caught and not is_another_fish_caught():
		attach_to_hook()

func attach_to_hook():
	is_aggro = false
	is_caught = true
	global_position = hook.global_position + Vector2(0, 10)
	get_tree().root.set_meta("fish_caught", true)
	print("[DEBUG] Fish caught! Weight:", weight)

func set_random_angle():
	# Pick a random angle in degrees from either range 10-35° or 160-200°
	var angle: float
	if randi() % 2 == 0:
		angle = randf_range(10, 35)
	else:
		angle = randf_range(160, 200)

	# Convert the angle to a Vector2 direction
	direction = Vector2.RIGHT.rotated(deg_to_rad(angle)).normalized()

func _on_angle_change_timer_timeout():
	# Change direction every time the timer triggers
	set_random_angle()

func is_another_fish_caught() -> bool:
	# Check if any other fish is already caught
	return get_tree().root.has_meta("fish_caught") and get_tree().root.get_meta("fish_caught")

func release_fish():
	# Call this function to release the fish and allow others to be caught
	is_caught = false
	get_tree().root.set_meta("fish_caught", false)
	print("[DEBUG] Fish released!")
