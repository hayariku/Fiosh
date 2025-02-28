# Attach this to the Door (Area2D) node

extends Area2D

# Path to the next scene
const NEXT_SCENE_PATH = "res://boss_arena.tscn"

func _ready():
	# Connect the body_entered signal to detect collision
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":  # Replace with your player's node name
		get_tree().change_scene_to_file("res://boss_arena.tscn")
