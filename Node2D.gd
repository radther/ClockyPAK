extends Node2D

const EXIT_BUTTON = 8   # Adjust if your controller uses a different index
const A_BUTTON = 1
const B_BUTTON = 2
const SELECT_BUTTON = 6  # Adjust if your controller uses a different index

onready var log_label       = $Log
onready var hours_label     = $Hours
onready var minutes_label   = $Minutes
onready var _tween          = $Tween
onready var _eyes           = $Eyes
onready var _eye_tweener    = $EyeTweener
onready var _eye_animations = $EyeAnimations

var quitting    = false
var last_second = -1

func _ready():
	log_label.visible = false
	log_label.add_text("Ready — press any key\n")
	hours_label.rect_pivot_offset   = hours_label.rect_size   / 2
	minutes_label.rect_pivot_offset = minutes_label.rect_size / 2
	_eye_tweener.setup(_tween, _eyes, hours_label, minutes_label)
	_eye_animations.setup(_tween, _eye_tweener)

func _process(_delta):
	var time = OS.get_time()
	if time.second != last_second:
		last_second = time.second
		hours_label.text   = "%02d" % [time.hour]
		minutes_label.text = "%02d" % [time.minute]

func _input(event):
	_print_input(event)
	if _isKeyOrButton(event, KEY_A, EXIT_BUTTON):
		_quit()
	elif _isKeyOrButton(event, KEY_B, A_BUTTON):
		_eye_animations.play_peek()
	elif _isKeyOrButton(event, KEY_C, B_BUTTON):
		_eye_animations.play_happy()
	elif _isKeyOrButton(event, KEY_S, SELECT_BUTTON):
		log_label.visible = !log_label.visible

func _quit():
	if not quitting:
		quitting = true
		log_label.add_text("Quitting in 5 seconds...\n")
		yield(get_tree().create_timer(5.0), "timeout")
		get_tree().quit()

func _print_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var key_name = OS.get_scancode_string(event.scancode)
		log_label.add_text("Key: " + key_name + "\n")
	elif event is InputEventJoypadButton and event.pressed:
		log_label.add_text("Gamepad Button: " + str(event.button_index) + "\n")
	elif event is InputEventMouseButton and event.pressed:
		log_label.add_text("Mouse Button: " + str(event.button_index) + "\n")

func _isKeyOrButton(event, key, button):
	return ((event is InputEventKey and event.pressed and not event.echo and event.scancode == key) or
		(event is InputEventJoypadButton and event.pressed and event.button_index == button))
