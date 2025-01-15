extends CharacterBody2D

# Constants and variables for basic behavior
const AGGRO_RANGE = 500
const ATTACK_RANGE_MIN = 200
const ATTACK_RANGE_MAX = 350
const RETREAT_RANGE = 200
const MOVE_SPEED = 150
const RUN_AWAY_SPEED = 150
const ATTACK_COOLDOWN = 1.0
const MAX_HEALTH = 50
const attack_start_delay = 0.5  # Delay before starting the beam attack

# Beam-specific properties
@export var beam_damage: int = 10
@export var beam_delay: float = 0.25
@export var beam_length: float = 2000  # Length of the beam (longer than the screen)
@export var damage_delay: float = 0.25  # Delay before dealing damage
@export var beam_hit_tolerance: float = 35  # Tolerance for detecting if the player is on the beam

var player: Node2D = null
var state: String = "idle"
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var health: int = MAX_HEALTH
var last_beam_points: Array = []
var beam_active: bool = false  # Tracks if the beam is active for hit detection
var current_beam: Line2D = null  # Reference to the current beam

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

signal slime_died



func _ready():
	player = get_parent().get_node("Player")
	health_bar.max_value = MAX_HEALTH
	health_bar.value = health
	

func _physics_process(delta):
	if player and player.is_inside_tree():
		var distance_to_player = position.distance_to(player.position)

		if state == "idle" and distance_to_player <= AGGRO_RANGE:
			state = "chasing"
			sprite.play("moving")

		if state == "chasing":
			if distance_to_player < RETREAT_RANGE:
				state = "retreating"
				sprite.play("moving")
			elif distance_to_player <= ATTACK_RANGE_MAX and distance_to_player >= ATTACK_RANGE_MIN:
				if cooldown_timer <= 0:
					state = "attacking"
					attack_timer = 0
					sprite.play("melee_attack")  # Use the regular attack animation
					await get_tree().create_timer(attack_start_delay).timeout  # Add delay before attack starts
					start_beam_attack()
			else:
				move_toward_player()
		elif state == "retreating":
			retreat_from_player(delta)
		elif state == "attacking":
			handle_attack(delta)

	cooldown_timer -= delta

func move_toward_player():
	var direction = (player.position - position).normalized()
	velocity = direction * MOVE_SPEED
	move_and_slide()

	sprite.flip_h = player.position.x > position.x

func retreat_from_player(delta):
	var direction_to_player = (self.position - player.position).normalized()
	var closest_ally = find_closest_ally()
	var combined_direction = direction_to_player

	if closest_ally:
		var direction_to_ally = (closest_ally.position - self.position).normalized()
		combined_direction = (direction_to_player + direction_to_ally).normalized()

	velocity = combined_direction * RUN_AWAY_SPEED
	move_and_slide()

	sprite.flip_h = velocity.x > 0

	if position.distance_to(player.position) > RETREAT_RANGE:
		state = "chasing"
		sprite.play("moving")

func handle_attack(delta):
	attack_timer += delta
	if attack_timer >= ATTACK_COOLDOWN:
		cooldown_timer = ATTACK_COOLDOWN
		state = "chasing"
		sprite.play("moving")
		beam_active = false  # Deactivate beam after attack ends

func start_beam_attack():
	print("Light Monster is preparing to fire a beam...")
	beam_active = false  # Ensure beam is inactive initially

	# Create a visual representation of the initial white beam
	draw_beam(Color(1, 1, 1))  # White beam initially

	# Schedule the beam to turn red and deal damage after damage_delay seconds
	await get_tree().create_timer(damage_delay).timeout
	_change_beam_to_red()

func _change_beam_to_red():
	# Change the beam color to red and apply damage in the same place as the white beam
	draw_beam(Color(1, 0, 0), last_beam_points)  # Red color
	beam_active = true  # Activate beam for hit detection

	# Damage is only applied if the player is on the beam
	if player and is_point_on_beam(player.global_position, last_beam_points[0], last_beam_points[1]):
		player.apply_damage(beam_damage)
		print("Light Monster's beam hit the player!")

func draw_beam(color: Color, points: Array = []):
	# Remove the existing beam line if it exists
	if current_beam:
		current_beam.queue_free()
		current_beam = null

	# Calculate beam points if not provided
	if points.is_empty():
		points = [global_position, global_position + (player.global_position - global_position).normalized() * beam_length]
		last_beam_points = points  # Save the points for the red beam

	# Create a new Line2D node for the beam
	current_beam = Line2D.new()
	current_beam.width = 4  # Adjust as needed for the visual size of the beam
	current_beam.points = points
	current_beam.default_color = color
	current_beam.z_index = 2  # Ensure it appears above other objects
	current_beam.position = Vector2.ZERO  # Ensure the position is relative to the parent node

	# Add the beam to the same parent node as this script
	get_parent().add_child(current_beam)

	# Debugging the beam creation
	print("Beam created with color: ", color, " and points: ", points)

func find_closest_ally() -> Node2D:
	var closest_ally = null
	var closest_distance = INF

	for child in get_parent().get_children():
		if child != self and (child.name == "LightMonster1" or child.name == "LightMonster2"):
			var distance = position.distance_to(child.position)
			if distance < closest_distance:
				closest_ally = child
				closest_distance = distance

	return closest_ally

func apply_damage(amount):
	health -= amount
	health = clamp(health, 0, MAX_HEALTH)
	health_bar.value = health
	print("Light Monster took damage! Remaining health: ", health)

	# If health is zero, delete the beam and trigger death
	if health <= 0:
		delete_beam()
		die()

func delete_beam():
	if current_beam:
		current_beam.queue_free()
		current_beam = null
		print("Beam deleted due to death.")

func die():
	if is_inside_tree():
		call_deferred("queue_free")
	emit_signal("slime_died")  # Notify the boss	

func is_point_on_beam(point: Vector2, start: Vector2, end: Vector2) -> bool:
	if not beam_active:  # Only check when the beam is active
		return false

	# Calculate the distance from the point to the line segment defined by start and end
	var beam_vector = end - start
	var point_vector = point - start

	# Calculate the projection of the point onto the beam vector
	var projection_length = point_vector.dot(beam_vector.normalized())

	# If the projection falls outside the beam segment, return false
	if projection_length < 0 or projection_length > beam_vector.length():
		return false

	# Find the closest point on the beam segment to the given point
	var closest_point = start + beam_vector.normalized() * projection_length

	# Check if the point is within the beam's hit tolerance
	return closest_point.distance_to(point) <= beam_hit_tolerance
