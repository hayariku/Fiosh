extends CharacterBody2D

# Fish behavior variables
@export var move_speed: float = 100.0
@export var detection_radius: float = 150.0
@export var angle_change_interval: float = 2.0  # Time interval (seconds) to change direction

# States
var is_aggro: bool = false
var direction: Vector2 = Vector2.ZERO
var hook: Node2D
var angle_timer: Timer

func _ready():
	# Reference the hook node (adjust the path as necessary)
	hook = get_parent().get_node("Hook")
	randomize()
	
	# Set up initial direction and timer for angle change
	set_random_angle()
	angle_timer = Timer.new()
	angle_timer.wait_time = angle_change_interval
	angle_timer.one_shot = false
	add_child(angle_timer)
	angle_timer.start()
	angle_timer.connect("timeout", Callable(self, "_on_angle_change_timer_timeout"))

func _physics_process(delta):
	if is_aggro:
		detect_and_move_to_hook()
	else:
		# Move the fish in the current direction
		velocity = direction * move_speed
		move_and_slide()

func patrol():
	# This function is unused in this new implementation but kept for future adjustments if needed
	pass

func detect_and_move_to_hook():
	if hook.global_position.distance_to(global_position) <= detection_radius:
		# Turn toward the hook
		direction = (hook.global_position - global_position).normalized()

		# Attach if touching the hook
		if hook.global_position.distance_to(global_position) < 10:
			attach_to_hook()

func attach_to_hook():
	is_aggro = false
	# Attach the fish to the hook by parenting it or setting its position to the hook
	global_position = hook.global_position
	print("Fish attached to hook!")

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
