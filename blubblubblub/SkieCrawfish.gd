extends CharacterBody2D

# Constants
const max_speed = 350
const reduced_speed = max_speed * 0.5  # 50% move speed during cooldown
const accel = 3000
const friction = 2500
const MAX_HEALTH = 100  # Player's maximum health
const ATTACK_RADIUS = 85  # Swing radius for the attack
const ATTACK_COOLDOWN = 0.4  # Cooldown duration after an attack
const DEATH_DELAY = 5.0  # Time to wait before returning to the start screen

# Variables
var input = Vector2.ZERO
var animation_state = "idle"
var health = MAX_HEALTH  # Initialize health
var cooldown_timer = 0.0  # Track cooldown time after an attack
var is_dead = false  # Track if the player is dead
var death_timer = 0.0  # Track time after death

# Node references
@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D  # Player-specific camera
@onready var health_bar = $PlayerHealthBar  # Assuming you have added a HealthBar node
@onready var attack_area = $AttackArea  # Attack detection Area2D node

func _ready():
	$Camera2D.make_current()
	health_bar.max_value = MAX_HEALTH  # Set the max value of the health bar
	health_bar.value = health  # Set the initial health value

func _physics_process(delta):
	if is_dead:
		# Update the death timer and transition to the start screen after DEATH_DELAY
		death_timer += delta
		if death_timer >= DEATH_DELAY:
			get_tree().change_scene_to_file("res://room.tscn")
		return  # Prevent all other logic if the player is dead

	if cooldown_timer > 0:
		cooldown_timer -= delta  # Reduce cooldown timer
	player_movement(delta)
	update_animation()
	check_attack()  # Check for attack input

# Function to handle input gathering
func get_input(): 
	input.x = int(Input.is_action_pressed("ui_right")) + int(Input.is_action_pressed("d")) - int(Input.is_action_pressed("ui_left")) - int(Input.is_action_pressed("a"))
	input.y = int(Input.is_action_pressed("ui_down")) + int(Input.is_action_pressed("s")) - int(Input.is_action_pressed("ui_up")) - int(Input.is_action_pressed("w"))
	return input.normalized()

# Function to manage player movement
func player_movement(delta):
	input = get_input()

	# Apply reduced speed during attack cooldown
	var current_speed = max_speed if cooldown_timer <= 0 else reduced_speed

	if input == Vector2.ZERO:
		if velocity.length() > (friction * delta):
			velocity -= velocity.normalized() * (friction * delta)
		else:
			velocity = Vector2.ZERO
	else:
		velocity += (input * accel * delta)
		velocity = velocity.limit_length(current_speed)
	move_and_slide()

# Function to update the animation based on movement
func update_animation():
	if input == Vector2.ZERO:
		if animation_state == "up":
			sprite.play("idle_up")
			sprite.flip_h = false
		elif animation_state == "down":
			sprite.play("idle_down")
			sprite.flip_h = false
		elif animation_state == "left":
			sprite.play("idle_left")
			sprite.flip_h = false
		elif animation_state == "right":
			sprite.play("idle_left")
			sprite.flip_h = true
	else:
		if input.y < 0:
			sprite.play("move_up")
			sprite.flip_h = false
			animation_state = "up"
		elif input.y > 0:
			sprite.play("move_down")
			sprite.flip_h = false
			animation_state = "down"
		elif input.x < 0:
			sprite.play("move_left")
			sprite.flip_h = false
			animation_state = "left"
		elif input.x > 0:
			sprite.play("move_left")
			sprite.flip_h = true
			animation_state = "right"

# Function to check for attack input
func check_attack():
	if Input.is_action_just_pressed("v") and cooldown_timer <= 0:
		perform_attack()
		cooldown_timer = ATTACK_COOLDOWN  # Start cooldown timer

# Function to perform the attack
func perform_attack():
	# Get all overlapping bodies within the attack radius
	var bodies = attack_area.get_overlapping_bodies()  # Uses AttackArea Area2D node

	for body in bodies:
		# Ensure the body is not the player itself
		if body != self and body.global_position.distance_to(position) <= ATTACK_RADIUS:
			# Apply damage to the target (assuming the body has an apply_damage method)
			if body.has_method("apply_damage"):
				body.apply_damage(20)  # Example damage amount; adjust as needed
				print("Hit: ", body)  # Print which body was hit

# Function to apply damage to the player and update health bar
func apply_damage(amount):
	if is_dead:
		return  # Ignore damage if the player is already dead

	health -= amount
	health = clamp(health, 0, MAX_HEALTH)  # Ensure health stays within range
	health_bar.value = health  # Update health bar value
	
	if health <= 0:
		die()  # Call the death function when health reaches zero
	else:
		print("Player took damage! Remaining health: ", health)  # Print hit detection message

# Function to handle player death
func die():
	is_dead = true  # Set the player as dead
	death_timer = 0.0  # Reset the death timer
	sprite.play("death")  # Play a death animation if available
	velocity = Vector2.ZERO  # Stop all movement
	print("You died!")  # Print death message
