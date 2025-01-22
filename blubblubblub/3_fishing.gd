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
var gravity = 400
var move_speed = 200.0
var fishing_radius = 400
var effective_radius = 0.0
var hook_hit_water = false
var can_reel = false
var reel_enabled = false

# Cast distance and line length based on rod level and spool level
var rodlvl = 2
var spoollvl = 2

@onready var hook = $Hook
@onready var sprite = $Hook/Sprite2D
@onready var camera = $Hook/Camera2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var charge_progress = $Hook/Camera2D/AnimatedSprite2D2

func _ready():
	origin_position = hook.global_position
	camera.make_current()
	charge_progress.visible = false
	print("Camera and sprite initialized.")
	

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
	elif Input.is_action_pressed("j") and not casting and can_cast:
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
	charge_progress.visible = true
	charge_progress.play("charge")

	effective_radius = fishing_radius * spoollvl
	print("Starting cast. Effective radius set to:", effective_radius)

# Charge cast when holding "j"
func charge_cast(delta):
	cast_time += delta
	print("max: ", max_cast_time, " currently ",cast_time)
	if cast_time > max_cast_time:
		cast_time = max_cast_time

	cast_strength = (cast_time / max_cast_time) * (100 + 250 * rodlvl)
	
	if Input.is_action_just_released("j"):
		animated_sprite.speed_scale = 1.0
		animated_sprite.play("Cast")
		charge_progress.stop()
		charge_progress.visible = false
		cast_hook()

# Apply physics to the hook and cast
func cast_hook():
	casting = false
	is_fishing = true
	can_move_hook = false
	reel_enabled = false

	var angle = -45.0
	var radians = deg_to_rad(angle)

	var velocity_multiplier = 2.0
	cast_velocity = Vector2(
		cast_strength * cos(radians) * velocity_multiplier,
		cast_strength * sin(radians) * 1.5 * velocity_multiplier
	)

func apply_physics(delta):
	cast_velocity.y += gravity * delta
	hook.global_position += cast_velocity * delta

	# Check if hook hits the water
	if hook.global_position.y >= 500 and not hook_hit_water:
		hook_hit_water = true
		cast_velocity = Vector2.ZERO
		can_move_hook = true
		var distance_from_origin = hook.global_position.distance_to(origin_position)
		effective_radius = distance_from_origin
		print("Hook hit water. Effective radius set to:", effective_radius)

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
		print("Reeling in. Updated effective radius to:", effective_radius)

	print("Effective Radius: ", effective_radius, " | Current Height: ", hook.global_position.y)

	if current_distance < 80:
		hook.global_position = origin_position
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
