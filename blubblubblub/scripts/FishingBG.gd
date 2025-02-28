extends TextureRect

# List of textures (using your image names from the res folder)
var textures = []
var current_frame = 0  # The current frame of the animation
var frame_time = 0.2  # Time in seconds between frames
var time_passed = 0.0  # Tracks how much time has passed

func _ready():
	# Load the textures into the array from the res:// folder
	textures = [
		load("res://3F1.png"),
		load("res://3F2.png"),
		load("res://3F3.png"),
		load("res://3F4.png"),
		load("res://3F5.png")
	]
	texture = textures[current_frame]  # Set the initial texture

func _process(delta):
	# Update the time passed
	time_passed += delta
	
	# If enough time has passed, switch to the next frame
	if time_passed >= frame_time:
		time_passed = 0.0  # Reset the time counter
		
		# Go to the next frame, looping back to the first if needed
		current_frame = (current_frame + 1) % textures.size()
		# Update the texture of the TextureRect
		texture = textures[current_frame]
