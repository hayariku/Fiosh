extends CharacterBody2D

const IDLE_RANGE = 500
const LUNGE_SPEED = 600
const ATTACK_COOLDOWN = 0.15
const POST_ATTACK_DELAY = 1
const LUNGE_DELAY = 2.5
const TRACKING_TIME = 0.75  # Half the lunge delay for tracking
const ACCEL = 400
const MAX_SPEED = 150
const MAX_HEALTH = 80  # Max health for the monster

var player = null
var state = "idle"
var attack_timer = 0.0
var lunge_direction = Vector2.ZERO
var post_attack_cooldown = 0.0
var health = MAX_HEALTH  # Initialize health
var tracking_timer = 0.0  # Timer for tracking before lunging
var damage_dealt = false  # Track if damage has been dealt during the attack

@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var health_bar = $HealthBar  # Ensure the ProgressBar node exists with this name

signal slime_died

func _ready():
	player = get_parent().get_node("Player")
	health_bar.max_value = MAX_HEALTH  # Set the max value of the health bar
	health_bar.value = health  # Set initial health bar value
	set_initial_health_bar_size()  # Set the initial size of the health bar

func _physics_process(delta):
	if post_attack_cooldown > 0:
		post_attack_cooldown -= delta
		return

	if state == "attack":
		handle_attack(delta)
	else:
		if player and player.is_inside_tree():  # Ensure player is valid
			var distance_to_player = position.distance_to(player.position)
			if distance_to_player < IDLE_RANGE:
				if state == "idle":
					state = "chasing"
					sprite.play("moving")
			else:
				state = "idle"
				sprite.play("idle")

			if state == "chasing":
				move_toward_player()

func move_toward_player():
	var direction = (player.position - position).normalized()
	velocity = direction * MAX_SPEED
	move_and_slide()

	if player.position.x > position.x:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	if position.distance_to(player.position) < 120:
		start_attack()

# Function to start the attack sequence, initializing tracking first
func start_attack():
	state = "attack"
	attack_timer = 0.0
	tracking_timer = 0.0  # Start tracking timer
	sprite.play("melee_attack")
	velocity = Vector2.ZERO
	damage_dealt = false  # Reset damage dealt flag

# Function to handle the attack logic with tracking and lunge
func handle_attack(delta):
	attack_timer += delta

	if attack_timer < TRACKING_TIME:
		# While in the tracking phase, update the lunge direction to track the player
		tracking_timer += delta
		lunge_direction = (player.position - position).normalized()

	elif attack_timer >= TRACKING_TIME and attack_timer < TRACKING_TIME + ATTACK_COOLDOWN:
		# After tracking phase, lunge toward the direction at the end of the tracking phase
		velocity = lunge_direction * LUNGE_SPEED
		move_and_slide()

	elif attack_timer >= TRACKING_TIME + ATTACK_COOLDOWN:
		# After the attack finishes, return to chasing state
		state = "chasing"
		sprite.play("moving")
		velocity = Vector2.ZERO
		post_attack_cooldown = POST_ATTACK_DELAY

		# Deal damage only once per attack
		if position.distance_to(player.position) < 70:
			if not damage_dealt and player and player.is_inside_tree():
				player.apply_damage(30)  # Assuming a damage amount of 10
				damage_dealt = true  # Set flag to true after dealing damage

# Function to apply damage to the monster
func apply_damage(amount):
	health -= amount
	health = clamp(health, 0, MAX_HEALTH)  # Ensure health stays within range
	health_bar.value = health  # Update health bar value
	update_health_bar()
	
	print("Light Monster took damage! Remaining health: ", health)  # Print hit detection message

	if health <= 0:
		die()  # Call the death function when health reaches zero

# Function to handle death logic
func die():
	queue_free()  # Remove the monster from the scene when it dies
	emit_signal("slime_died")  # Notify the boss

# Function to set the initial size of the health bar
func set_initial_health_bar_size():
	var initial_width = 2 * MAX_HEALTH  # Double the max health for the initial width
	health_bar.size = Vector2(initial_width, 15)  # Set the initial size with a height of 15
	health_bar.position = Vector2(-initial_width / 2.0, -65)  # Center the health bar horizontally

# Function to update the health bar position without changing its width
func update_health_bar():
	health_bar.position = Vector2(-health_bar.size.x / 2.0, -65)  # Keep centered as health decreases
