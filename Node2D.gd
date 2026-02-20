extends Node2D

const EXIT_BUTTON = 8   # Adjust if your controller uses a different index
const A_BUTTON = 1
const SELECT_BUTTON = 6  # Adjust if your controller uses a different index

onready var log_label = $Log
onready var hours_label = $Hours
onready var minutes_label = $Minutes

var quitting = false
var last_second = -1
var tween: Tween
var left_eye: Panel
var right_eye: Panel
var _pending: Dictionary = {}
var _pending_eye_own_scale: Dictionary = {}    # Panel -> float (own-center scale, default 1.0)
var _pending_eye_center_scale: Dictionary = {} # Panel -> float (from-center scale, default 1.0)
var _pending_eye_shift: Dictionary = {}        # Panel -> float (x pixel offset, default 0.0)
var _eye_configs: Dictionary = {}              # Panel -> {shift_holder, csh, osh, base_center, full_size}
var _eye_common_x: float = 0.0                # midpoint between the two eye centers

func _make_eye(center: Vector2) -> Panel:
	var full_size = Vector2(200, 400)

	# shift_holder: owns lateral shift (rect_position:x)
	var shift_holder = Control.new()
	shift_holder.rect_position = center
	add_child(shift_holder)
	move_child(shift_holder, 0)

	# csh (center_scale_holder): owns from-center scale (rect_scale + rect_position:x within shift_holder)
	var csh = Control.new()
	shift_holder.add_child(csh)

	# osh (own_scale_holder): owns own-center scale (rect_scale)
	var osh = Control.new()
	csh.add_child(osh)

	var style = StyleBoxFlat.new()
	style.bg_color = Color.white
	style.set_corner_radius_all(48)
	var panel = Panel.new()
	panel.add_stylebox_override("panel", style)
	panel.rect_size = Vector2(full_size.x, 0)           # start closed
	panel.rect_position = Vector2(-full_size.x / 2, 0)  # centered on osh origin
	osh.add_child(panel)

	_eye_configs[panel] = {
		"shift_holder": shift_holder,
		"csh": csh,
		"osh": osh,
		"base_center": center,
		"full_size": full_size
	}
	return panel

func _ready():
	log_label.visible = false
	log_label.add_text("Ready — press any key\n")
	left_eye  = _make_eye(Vector2(342, 384))
	right_eye = _make_eye(Vector2(684, 384))
	_eye_common_x = (_eye_configs[left_eye].base_center.x + _eye_configs[right_eye].base_center.x) / 2.0
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
	var sh = config.shift_holder
	var base_x = config.base_center.x
	var from_x = _pending_eye_shift.get(panel, sh.rect_position.x - base_x)
	tween.interpolate_property(sh, "rect_position:x",
		base_x + from_x, base_x + target_x, duration, trans, ease_type, delay)
	_pending_eye_shift[panel] = target_x

# Scales each eye around its own center. Runs on osh.rect_scale.
func _tween_eye_scale(panel: Panel, duration: float, delay: float, target_s: float, trans: int, ease_type: int):
	var osh = _eye_configs[panel].osh
	var from_s = _pending_eye_own_scale.get(panel, osh.rect_scale.x)
	tween.interpolate_property(osh, "rect_scale",
		Vector2(from_s, from_s), Vector2(target_s, target_s), duration, trans, ease_type, delay)
	_pending_eye_own_scale[panel] = target_s

# Scales each eye around the shared midpoint. Runs on csh.rect_scale + csh.rect_position:x.
# These properties are separate from shift_holder and osh, so all four effects run in parallel.
func _tween_eye_center_scale(panel: Panel, duration: float, delay: float, target_s: float, trans: int, ease_type: int):
	var config = _eye_configs[panel]
	var csh = config.csh
	var base_x = config.base_center.x
	var from_s = _pending_eye_center_scale.get(panel, csh.rect_scale.x)
	tween.interpolate_property(csh, "rect_scale",
		Vector2(from_s, from_s), Vector2(target_s, target_s), duration, trans, ease_type, delay)
	tween.interpolate_property(csh, "rect_position:x",
		(base_x - _eye_common_x) * (from_s - 1.0),
		(base_x - _eye_common_x) * (target_s - 1.0),
		duration, trans, ease_type, delay)
	_pending_eye_center_scale[panel] = target_s

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

func _scale_eyes_from_center(duration: float, delay: float, target: float):
	_tween_eye_center_scale(left_eye,  duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_tween_eye_center_scale(right_eye, duration, delay, target, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func _play_blink():
	tween.stop_all()
	_pending.clear()
	_pending_eye_own_scale.clear()
	_pending_eye_center_scale.clear()
	_pending_eye_shift.clear()
	_close_clock(0.1, 0.0)
	_open_left_eye(0.1, 0.1, 0.5)
	_open_right_eye(0.1, 0.6, 0.5)
	_open_both_eyes(0.1, 0.7, 1)
	_open_both_eyes(4, 1, 0.3)
	_scale_eyes(4, 1, 1.2)
	_scale_eyes_from_center(4, 1, 1.2)
	_scale_eyes(0.1, 7, 1)
	_open_both_eyes(0.1, 7, 1)
	_close_both_eyes(0.1, 8)
	_open_clock(0.1, 8.2)
	tween.start()

func _input(event):
	_print_input(event)
	if _isKeyOrButton(event, KEY_A, EXIT_BUTTON):
		_quit()
	elif _isKeyOrButton(event, KEY_B, A_BUTTON):
		_play_blink()
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
