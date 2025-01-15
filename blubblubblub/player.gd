extends CharacterBody2D

const max_speed = 300
const accel = 900
const friction = 2500

# Fishing-related variables
var rodlvl = 1
var linelvl = 1
var baitlvl = 1
var spoollvl = 1
var hooklvl = 1

var input = Vector2.ZERO
var animation_state = "idle"

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D  # Player-specific camera

func _ready():
	$Camera2D.make_current()

func _physics_process(delta):
	player_movement(delta)
	update_animation()

	if Input.is_action_just_pressed("g"):
		# Switch to fishing scene
		get_tree().change_scene_to_file("res://3Fishing.tscn")
		
	if Input.is_action_just_pressed("p"):
		# Switch to another scene
		get_tree().change_scene_to_file("res://room.tscn")

func get_input(): 
	input.x = int(Input.is_action_pressed("ui_right")) + int(Input.is_action_pressed("d")) - int(Input.is_action_pressed("ui_left")) - int(Input.is_action_pressed("a"))
	input.y = int(Input.is_action_pressed("ui_down")) + int(Input.is_action_pressed("s")) - int(Input.is_action_pressed("ui_up")) - int(Input.is_action_pressed("w"))
	return input.normalized()

func player_movement(delta):
	input = get_input()

	if input == Vector2.ZERO:
		if velocity.length() > (friction * delta):
			velocity -= velocity.normalized() * (friction * delta)
		else:
			velocity = Vector2.ZERO
	else:
		velocity += (input * accel * delta)
		velocity = velocity.limit_length(max_speed)
	move_and_slide()

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
