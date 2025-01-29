extends Node2D

# Hook casting variables
var casting = false
var cast_strength = 50.0
var cast_time = 0.0
var cast_velocity = Vector2.ZERO
var max_cast_time = 3.0
var origin_position = Vector2.ZERO
var can_cast = true
var can_move_hook = false

# Fishing variables
var is_fishing = false
var reel_speed = 500.0
var gravity = 150.0
var move_speed = 200.0
var fishing_radius = 400
var effective_radius = 0.0
var hook_hit_water = false
var can_reel = false
var reel_enabled = false

# Cast distance and line length based on rod level and spool level
var rodlvl = 3
var spoollvl = 3

# Fish spawning variables
var fish_scene = preload("res://fish_1.tscn")
var fish_count = 20
var fish_list = []

@onready var hook = $Hook
@onready var sprite = $Hook/Sprite2D
@onready var camera = $Hook/Camera2D
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	origin_position = hook.global_position
	camera.make_current()
	print("[DEBUG] Camera and sprite initialized.")
	spawn_fish()  # Spawn fish when the game starts

func _physics_process(delta):
	handle_input(delta)

	if casting:
		charge_cast(delta)
	elif is_fishing:
		apply_physics(delta)

	move_hook(delta)

# Handle input for casting and fishing
func handle_input(delta):
	if Input.is_action_pressed("F") and reel_enabled:
		pull_back_to_origin(delta, true)
	elif Input.is_action_pressed("f") and reel_enabled:
		pull_back_to_origin(delta)
	elif Input.is_action_just_pressed("j") and not casting and can_cast:
		start_cast()
	elif Input.is_action_just_pressed("g") and not is_fishing:
		get_tree().change_scene_to_file("res://2FishermanMain.tscn")

# Start casting and reset variables
func start_cast():
	casting = true
	can_cast = false
	hook_hit_water = false
	cast_strength = 0.0
	cast_time = 0.0
	cast_velocity = Vector2.ZERO
	can_move_hook = false

	animated_sprite.speed_scale = 2.0
	animated_sprite.play("PullBack")

	effective_radius = fishing_radius * spoollvl
	print("[DEBUG] Starting cast. Effective radius set to:", effective_radius)

# Charge cast when holding "j"
func charge_cast(delta):
	cast_time += delta
	if cast_time > max_cast_time:
		cast_time = max_cast_time

	cast_strength = (cast_time / max_cast_time) * (80 * rodlvl)

	if Input.is_action_just_released("j"):
		animated_sprite.speed_scale = 1.0
		animated_sprite.play("Cast")
		cast_hook()

# Apply faster physics to the hook and cast
func cast_hook():
	casting = false
	is_fishing = true
	can_move_hook = false
	reel_enabled = false

	var angle = -35.0
	var radians = deg_to_rad(angle)

	var velocity_multiplier = 3.5  # Increased casting speed
	cast_velocity = Vector2(
		cast_strength * cos(radians) * velocity_multiplier,
		cast_strength * sin(radians) * 1.8 * velocity_multiplier  # Faster downward speed
	)

func apply_physics(delta):
	# Increase gravity effect above water for faster falling
	if hook.global_position.y < 500:
		cast_velocity.y += gravity * 2.5 * delta  # Stronger gravity above water
	else:
		cast_velocity.y += gravity * delta  # Normal gravity below water

	hook.global_position += cast_velocity * delta

	# Check if hook hits the water
	if hook.global_position.y >= 500 and not hook_hit_water:
		hook_hit_water = true
		cast_velocity = Vector2.ZERO
		can_move_hook = true
		var distance_from_origin = hook.global_position.distance_to(origin_position)
		effective_radius = distance_from_origin
		print("[DEBUG] Hook hit water. Effective radius set to:", effective_radius)

	# Enable reeling once hook is below a certain Y position
	if hook.global_position.y >= 500 and not reel_enabled:
		reel_enabled = true

	# Limit hook's movement based on spool length
	var distance_from_origin = hook.global_position.distance_to(origin_position)
	if distance_from_origin > effective_radius:
		var constrained_position = origin_position + (hook.global_position - origin_position).normalized() * effective_radius
		hook.global_position = constrained_position
		cast_velocity.x = 0  # Reset horizontal velocity
		if hook.global_position.y < 500:
			cast_velocity.y += gravity * delta

# Hook movement control while fishing
func move_hook(delta):
	if is_fishing and can_move_hook:
		if Input.is_action_pressed("ui_left"):
			hook.position.x -= move_speed * delta
		elif Input.is_action_pressed("ui_right"):
			hook.position.x += move_speed * delta

# Pull hook back to origin when reeling
func pull_back_to_origin(delta, fast_reel = false):
	if not reel_enabled:
		return

	cast_velocity.y = 0

	var reel_factor = 1.0
	if fast_reel:
		reel_factor = 3.0

	var direction_to_origin = (origin_position - hook.global_position).normalized()
	var distance_moved = reel_speed * reel_factor * delta
	hook.global_position += direction_to_origin * distance_moved

	var current_distance = hook.global_position.distance_to(origin_position)

	if current_distance + 20 < effective_radius:
		effective_radius = current_distance + 30
		print("[DEBUG] Reeling in. Updated effective radius to:", effective_radius)

	print("[DEBUG] Effective Radius:", effective_radius, " | Current Height:", hook.global_position.y)

	# When the hook is close enough to the origin, finalize
	if current_distance < 80:
		hook.global_position = origin_position
		collect_caught_fish()  # Check for caught fish and collect them
		reset_casting_variables()

# Reset casting variables once reeling is complete
func reset_casting_variables():
	casting = false
	can_cast = true
	is_fishing = false
	hook_hit_water = false
	reel_enabled = false
	cast_strength = 50.0
	cast_time = 0.0
	cast_velocity = Vector2.ZERO
	effective_radius = fishing_radius * spoollvl
	hook.global_position = origin_position
	can_move_hook = false

# Spawn multiple fish at random positions
func spawn_fish():
	for i in range(fish_count):
		var fish = fish_scene.instantiate()
		var random_position = Vector2(randf_range(-fishing_radius, fishing_radius), randf_range(400, 600))
		fish.global_position = random_position

		add_child(fish)
		fish_list.append(fish)

		print("[DEBUG] Fish spawned at:", random_position)

	print("[DEBUG] Current fish count:", fish_list.size())

# Collect caught fish once the hook is reeled in
func collect_caught_fish():
	var caught_fish = []

	# Find any fish that have is_caught == true
	for fish in fish_list:
		if is_instance_valid(fish) and fish.is_caught:
			caught_fish.append(fish)

	# Remove them from the scene and the fish_list
	for fish in caught_fish:
		if is_instance_valid(fish):
			fish_list.erase(fish)
			fish.queue_free()
			print("[DEBUG] Fish collected!")

	# Reset the "fish_caught" meta so a new fish can be caught later
	if get_tree().root.has_meta("fish_caught"):
		get_tree().root.set_meta("fish_caught", false)

	print("[DEBUG] Fish count after collection:", fish_list.size())
