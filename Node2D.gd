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
var _pending: Dictionary = {}  # tracks pending y-scale per node for chained animations
var _eye_configs: Dictionary = {}  # Panel -> {center, full_size} for rect_size/position animation

func _make_eye(center: Vector2) -> Panel:
	var full_size = Vector2(200, 400)
	var style = StyleBoxFlat.new()
	style.bg_color = Color.white
	style.set_corner_radius_all(48)
	var panel = Panel.new()
	panel.add_stylebox_override("panel", style)
	panel.rect_size = Vector2(full_size.x, 0)  # start closed
	panel.rect_position = Vector2(center.x - full_size.x / 2, center.y)  # collapsed at vertical center
	add_child(panel)
	move_child(panel, 0)  # render behind labels
	_eye_configs[panel] = {"center": center, "full_size": full_size}
	return panel

func _ready():
	log_label.add_text("Ready — press any key\n")
	left_eye = _make_eye(Vector2(342, 384))
	right_eye = _make_eye(Vector2(684, 384))
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

func _tween_scale_y(node, duration: float, delay: float, target_y: float, trans: int, ease_type: int):
	var from_y = _pending.get(node, node.rect_scale.y)
	tween.interpolate_property(node, "rect_scale",
		Vector2(1, from_y), Vector2(1, target_y), duration, trans, ease_type, delay)
	_pending[node] = target_y

func _tween_eye_y(panel: Panel, duration: float, delay: float, target_y: float, trans: int, ease_type: int):
	var config = _eye_configs[panel]
	var full_h: float = config.full_size.y
	var left_x: float = config.center.x - config.full_size.x / 2
	var center_y: float = config.center.y
	var from_y = _pending.get(panel, panel.rect_size.y / full_h)
	var from_h = from_y * full_h
	var to_h = target_y * full_h
	tween.interpolate_property(panel, "rect_size",
		Vector2(config.full_size.x, from_h), Vector2(config.full_size.x, to_h),
		duration, trans, ease_type, delay)
	tween.interpolate_property(panel, "rect_position",
		Vector2(left_x, center_y - from_h / 2), Vector2(left_x, center_y - to_h / 2),
		duration, trans, ease_type, delay)
	_pending[panel] = target_y

func _close_clock(duration: float, delay: float, target: float = 0.0):
	_tween_scale_y(hours_label, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN)
	_tween_scale_y(minutes_label, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN)

func _open_clock(duration: float, delay: float, target: float = 1.0):
	_tween_scale_y(hours_label, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_OUT)
	_tween_scale_y(minutes_label, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_OUT)

func _open_left_eye(duration: float, delay: float, target: float = 1.0):
	_tween_eye_y(left_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_OUT)

func _close_left_eye(duration: float, delay: float, target: float = 0.0):
	_tween_eye_y(left_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN)

func _open_right_eye(duration: float, delay: float, target: float = 1.0):
	_tween_eye_y(right_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_OUT)

func _close_right_eye(duration: float, delay: float, target: float = 0.0):
	_tween_eye_y(right_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN)

func _open_both_eyes(duration: float, delay: float, target: float = 1.0):
	_open_left_eye(duration, delay, target)
	_open_right_eye(duration, delay, target)

func _close_both_eyes(duration: float, delay: float, target: float = 0.0):
	_close_left_eye(duration, delay, target)
	_close_right_eye(duration, delay, target)

func _play_blink():
	tween.stop_all()
	_pending.clear()
	_close_clock(0.1, 0.0)
	_open_left_eye(0.1, 0.1, 0.5)
	_open_right_eye(0.1, 0.1, 0.1)
	_open_both_eyes(0.3, 1.1)
	_close_both_eyes(0.1, 3)
	_open_clock(0.1, 3.1)
	tween.start()

func _input(event):
	_print_input(event)
	if _isKeyOrButton(event, KEY_A, START_BUTTON):
#		if event.scancode == KEY_A:
		_quit()
	elif _isKeyOrButton(event, KEY_B, A_BUTTON):
		_play_blink()

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
