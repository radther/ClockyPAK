extends Node2D

const START_BUTTON = 7  # Adjust if your controller uses a different index
const A_BUTTON = 1

onready var log_label = $Log
onready var hours_label = $Hours
onready var minutes_label = $Minutes

var quitting = false
var last_second = -1
var tween: Tween
var left_eye: Panel
var right_eye: Panel

func _make_eye(center: Vector2) -> Panel:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.white
	style.set_corner_radius_all(48)
	var panel = Panel.new()
	panel.add_stylebox_override("panel", style)
	panel.rect_size = Vector2(200, 400)
	panel.rect_position = center - panel.rect_size / 2
	add_child(panel)
	move_child(panel, 0)  # render behind labels
	return panel

func _ready():
	log_label.add_text("Ready — press any key\n")
	left_eye = _make_eye(Vector2(342, 384))
	right_eye = _make_eye(Vector2(684, 384))
	# Pivot at vertical center so the squish closes from both edges inward
	hours_label.rect_pivot_offset = hours_label.rect_size / 2
	minutes_label.rect_pivot_offset = minutes_label.rect_size / 2
	tween = Tween.new()
	add_child(tween)

func _process(_delta):
	var time = OS.get_time()
	if time.second != last_second:
		last_second = time.second
		hours_label.text = "%02d" % [time.hour]
		minutes_label.text = "%02d" % [time.minute]

func _close_eyes():
	tween.stop_all()
	tween.interpolate_property(hours_label, "rect_scale",
		Vector2(1, 1), Vector2(1, 0), 0.1,
		Tween.TRANS_SINE, Tween.EASE_IN)
	tween.interpolate_property(minutes_label, "rect_scale",
		Vector2(1, 1), Vector2(1, 0), 0.1,
		Tween.TRANS_SINE, Tween.EASE_IN)
	tween.start()

func _input(event):
	_print_input(event)
	if _isKeyOrButton(event, KEY_A, START_BUTTON):
#		if event.scancode == KEY_A:
		_quit()
	elif _isKeyOrButton(event, KEY_B, A_BUTTON):
		_close_eyes()

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
