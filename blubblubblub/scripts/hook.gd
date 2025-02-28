extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var hook = 0
var ti = 0

func _physics_process(delta: float) -> void:
	# Add the gravity.

	# Handle jump.
	if Input.is_action_just_pressed("hook"):
		velocity.y = -400
		velocity.x = 500
		hook = 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
