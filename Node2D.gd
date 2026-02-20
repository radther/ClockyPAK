extends Node2D

const START_BUTTON = 7  # Adjust if your controller uses a different index

onready var log_label = $Log
onready var hours_label = $Hours
onready var minutes_label = $Minutes

var quitting = false
var last_second = -1

func _ready():
	log_label.add_text("Ready — press any key\n")

func _process(_delta):
	var time = OS.get_time()
	if time.second != last_second:
		last_second = time.second
		hours_label.text = "%02d" % [time.hour]
		minutes_label.text = "%02d" % [time.minute]		

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var key_name = OS.get_scancode_string(event.scancode)
		log_label.add_text("Key: " + key_name + "\n")
		if event.scancode == KEY_A and not quitting:
			quitting = true
			log_label.add_text("A pressed — quitting in 5 seconds...\n")
			yield(get_tree().create_timer(5.0), "timeout")
			get_tree().quit()
	elif event is InputEventJoypadButton and event.pressed:
		log_label.add_text("Gamepad Button: " + str(event.button_index) + "\n")
		if event.button_index == START_BUTTON and not quitting:
			quitting = true
			log_label.add_text("Start pressed — quitting in 5 seconds...\n")
			yield(get_tree().create_timer(5.0), "timeout")
			get_tree().quit()
	elif event is InputEventMouseButton and event.pressed:
		log_label.add_text("Mouse Button: " + str(event.button_index) + "\n")
