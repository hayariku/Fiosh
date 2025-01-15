extends RigidBody2D

@export var velocity = Vector2.ZERO

func _ready():
	pass

func _physics_process(delta):
	position += velocity * delta

	# Destroy the projectile after leaving the screen or colliding
	if !is_inside_tree():
		queue_free()
