extends Control

# A list of dialogues to be shown
var dialogues = [
	"Ooh you're in rough shape.",
	"Let's get you patched up",
	"There, you should be all good now"
]

var characterName = [
	"k",
	"Raccoon",
	"???",
	"Skye Crawfish"
]

# Index to track the current dialogue
var current_dialogue_index = 0
var current_name_index = 0

# Reference the nodes using @onready
@onready var dialogue_label = $Panel/DialogueLabel
@onready var character_name = $Panel/CharacterName
@onready var next_button = $Panel/NextButton

func _ready():
	next_button.modulate.a = 0.0
	# Update the dialogue label with the first dialogue
	update_dialogue()
	update_name()
	# Connect the button's pressed signal
	next_button.pressed.connect(_on_next_button_pressed)

func update_dialogue():
	# Set the label to display the current dialogue
	dialogue_label.text = dialogues[current_dialogue_index]
func update_name():
	character_name.text = characterName[current_name_index]

func _on_next_button_pressed():
	# Move to the next dialogue
	current_dialogue_index += 1
	# Loop back to the first dialogue after the last one
	if current_dialogue_index >= dialogues.size():
		current_dialogue_index = 0
	# Update the label with the new dialogue
	update_dialogue()
	update_name()
