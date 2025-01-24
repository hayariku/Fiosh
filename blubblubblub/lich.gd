extends CharacterBody2D

const MAX_HEALTH = 800
const SUMMON_COOLDOWN = 15.0  # Time before slimes respawn after dying
const SUMMON_POSITION_OFFSET = 100
const MELEE_SLIME_COUNT = 3
const RANGED_SLIME_COUNT = 2

var health = MAX_HEALTH
var summon_timer = SUMMON_COOLDOWN
var slimes = []  # List to track the active slimes

@onready var health_bar = $HealthBar

func _ready():
	health_bar.max_value = MAX_HEALTH
	health_bar.value = health
	randomize()  # Ensure random values vary each time the game runs
	summon_slimes()  # Initial slime summoning

func _physics_process(delta):
	# Update health bar
	health_bar.value = health

	# Handle slime respawning
	if not are_slimes_active():
		summon_timer -= delta
		if summon_timer <= 0:
			summon_slimes()
			summon_timer = SUMMON_COOLDOWN

# Function to check if slimes are active
func are_slimes_active() -> bool:
	for slime in slimes:
		if slime and slime.is_inside_tree():
			return true
	return false

# Function to summon slimes
func summon_slimes():
	# Clear the existing list of slimes
	slimes.clear()

	# Summon melee slimes
	for i in range(MELEE_SLIME_COUNT):
		var melee_slime = summon_slime("res://light_monster_1_1.tscn", "LightMonster1")
		if melee_slime:
			slimes.append(melee_slime)

	# Summon ranged slimes
	for i in range(RANGED_SLIME_COUNT):
		var ranged_slime = summon_slime("res://light_monster_2_1.tscn", "LightMonster2")
		if ranged_slime:
			slimes.append(ranged_slime)

	print("Slimes summoned!")

# Function to summon an individual slime
func summon_slime(scene_path: String, slime_name: String) -> Node2D:
	var slime_scene = load(scene_path)  # Use load for dynamic paths
	if slime_scene == null:
		print("Error: Failed to load scene at path: ", scene_path)
		return null

	var slime = slime_scene.instantiate() as Node2D
	slime.name = slime_name

	# Connect the slime's death signal to this boss
	slime.connect("slime_died", Callable(self, "_on_slime_died"))

	# Place the slime near the boss
	var random_offset = Vector2(
		randi_range(-SUMMON_POSITION_OFFSET, SUMMON_POSITION_OFFSET),
		randi_range(-SUMMON_POSITION_OFFSET, SUMMON_POSITION_OFFSET)
	)
	slime.position = global_position + random_offset

	# Add the slime to the scene
	get_parent().add_child(slime)
	return slime

# Signal handler for when a slime dies
func _on_slime_died(emitter):
	print(emitter.name, "died.")
	slimes.erase(emitter)  # Remove the dead slime from the active list

	# Determine which type of slime to respawn based on its name
	var scene_path = ""
	if emitter.name == "LightMonster1":
		scene_path = "res://light_monster_1_1.tscn"
	elif emitter.name == "LightMonster2":
		scene_path = "res://light_monster_2_1.tscn"

	# Respawn the same type of slime after the cooldown
	await respawn_slime(scene_path, emitter.name)

# Function to respawn a slime after a cooldown
func respawn_slime(scene_path: String, slime_name: String) -> void:
	await get_tree().create_timer(SUMMON_COOLDOWN).timeout
	var respawned_slime = summon_slime(scene_path, slime_name)
	if respawned_slime:
		slimes.append(respawned_slime)

# Function to apply damage to the boss
func apply_damage(amount):
	health -= amount
	if health <= 0:
		die()

# Function to handle boss death
func die():
	print("Boss defeated!")
	queue_free()  # Remove the boss from the scene
