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
var _pending: Dictionary = {}           # Panel -> pending y-fraction for open/close
var _pending_eye_scale: Dictionary = {} # Panel -> scale factor (default 1.0)
var _pending_eye_shift: Dictionary = {} # Panel -> x pixel offset (default 0.0)
var _eye_configs: Dictionary = {}       # Panel -> {holder, base_center, full_size}

func _make_eye(center: Vector2) -> Panel:
	var full_size = Vector2(200, 400)
	var holder = Control.new()
	holder.rect_position = center
	add_child(holder)
	move_child(holder, 0)

	var style = StyleBoxFlat.new()
	style.bg_color = Color.white
	style.set_corner_radius_all(48)
	var panel = Panel.new()
	panel.add_stylebox_override("panel", style)
	panel.rect_size = Vector2(full_size.x, 0)           # start closed
	panel.rect_position = Vector2(-full_size.x / 2, 0)  # centered on holder origin
	holder.add_child(panel)

	_eye_configs[panel] = {"holder": holder, "base_center": center, "full_size": full_size}
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
	var from_y = _pending.get(panel, panel.rect_size.y / full_h)
	var from_h = from_y * full_h
	var to_h   = target_y * full_h
	tween.interpolate_property(panel, "rect_size:y", from_h, to_h, duration, trans, ease_type, delay)
	tween.interpolate_property(panel, "rect_position:y", -from_h / 2, -to_h / 2, duration, trans, ease_type, delay)
	_pending[panel] = target_y

func _tween_eye_shift(panel: Panel, duration: float, delay: float, target_x: float, trans: int, ease_type: int):
	var config = _eye_configs[panel]
	var holder = config.holder
	var base_x = config.base_center.x
	var from_x = _pending_eye_shift.get(panel, holder.rect_position.x - base_x)
	tween.interpolate_property(holder, "rect_position:x",
		base_x + from_x, base_x + target_x, duration, trans, ease_type, delay)
	_pending_eye_shift[panel] = target_x

func _tween_eye_scale(panel: Panel, duration: float, delay: float, target_s: float, trans: int, ease_type: int):
	var holder = _eye_configs[panel].holder
	var from_s = _pending_eye_scale.get(panel, holder.rect_scale.x)
	tween.interpolate_property(holder, "rect_scale",
		Vector2(from_s, from_s), Vector2(target_s, target_s), duration, trans, ease_type, delay)
	_pending_eye_scale[panel] = target_s

func _close_clock(duration: float, delay: float, target: float = 0.0):
	_tween_scale_y(hours_label, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_tween_scale_y(minutes_label, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _open_clock(duration: float, delay: float, target: float = 1.0):
	_tween_scale_y(hours_label, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_tween_scale_y(minutes_label, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _open_left_eye(duration: float, delay: float, target: float = 1.0):
	_tween_eye_y(left_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _close_left_eye(duration: float, delay: float, target: float = 0.0):
	_tween_eye_y(left_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _open_right_eye(duration: float, delay: float, target: float = 1.0):
	_tween_eye_y(right_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _close_right_eye(duration: float, delay: float, target: float = 0.0):
	_tween_eye_y(right_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _open_both_eyes(duration: float, delay: float, target: float = 1.0):
	_open_left_eye(duration, delay, target)
	_open_right_eye(duration, delay, target)

func _close_both_eyes(duration: float, delay: float, target: float = 0.0):
	_close_left_eye(duration, delay, target)
	_close_right_eye(duration, delay, target)

func _shift_left_eye(duration: float, delay: float, amount: float):
	_tween_eye_shift(left_eye, duration, delay, amount, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _shift_right_eye(duration: float, delay: float, amount: float):
	_tween_eye_shift(right_eye, duration, delay, amount, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _shift_eyes(duration: float, delay: float, amount: float):
	_shift_left_eye(duration, delay, amount)
	_shift_right_eye(duration, delay, amount)

func _scale_left_eye(duration: float, delay: float, target: float):
	_tween_eye_scale(left_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _scale_right_eye(duration: float, delay: float, target: float):
	_tween_eye_scale(right_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _scale_eyes(duration: float, delay: float, target: float):
	_scale_left_eye(duration, delay, target)
	_scale_right_eye(duration, delay, target)

func _play_blink():
	tween.stop_all()
	_pending.clear()
	_pending_eye_scale.clear()
	_pending_eye_shift.clear()
	_close_clock(0.1, 0.0)
	_open_left_eye(0.1, 0.1, 0.5)
	_open_right_eye(0.1, 0.6, 0.5)
	_open_both_eyes(0.1, 0.7, 1)
	_open_both_eyes(1, 1, 0.3)
	_scale_eyes(4, 1, 1.4)
	_scale_eyes(0.1, 5, 1)
	_open_both_eyes(0.1, 5, 1)
	_close_both_eyes(0.1, 6)
	_open_clock(0.1, 6.2)
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
