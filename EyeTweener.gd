extends Node

var _tween: Tween
var _eyes           # Eyes node
var _hours_label: Label
var _minutes_label: Label

var _pending: Dictionary = {}
var _pending_eye_own_scale: Dictionary = {}    # Panel -> float (own-center scale, default 1.0)
var _pending_eye_center_scale: Dictionary = {} # Panel -> float (from-center scale, default 1.0)
var _pending_eye_shift: Dictionary = {}        # Panel -> float (x pixel offset, default 0.0)
var _pending_eye_shift_y: Dictionary = {}      # Panel -> float (y pixel offset, default 0.0)

func setup(tween: Tween, eyes, hours_label: Label, minutes_label: Label):
	_tween = tween
	_eyes  = eyes
	_hours_label  = hours_label
	_minutes_label = minutes_label

func reset_pending():
	_pending.clear()
	_pending_eye_own_scale.clear()
	_pending_eye_center_scale.clear()
	_pending_eye_shift.clear()
	_pending_eye_shift_y.clear()

func _tween_scale_y(node, duration: float, delay: float, target_y: float, trans: int, ease_type: int):
	var from_y = _pending.get(node, node.rect_scale.y)
	_tween.interpolate_property(node, "rect_scale",
		Vector2(1, from_y), Vector2(1, target_y), duration, trans, ease_type, delay)
	_pending[node] = target_y

func _tween_eye_y(panel: Panel, duration: float, delay: float, target_y: float, trans: int, ease_type: int):
	var config = _eyes._eye_configs[panel]
	var full_h: float = config.full_size.y
	var from_y = _pending.get(panel, panel.rect_size.y / full_h)
	var from_h = from_y * full_h
	var to_h   = target_y * full_h
	_tween.interpolate_property(panel, "rect_size:y", from_h, to_h, duration, trans, ease_type, delay)
	_tween.interpolate_property(panel, "rect_position:y", -from_h / 2, -to_h / 2, duration, trans, ease_type, delay)
	_pending[panel] = target_y

func _tween_eye_shift(panel: Panel, duration: float, delay: float, target_x: float, trans: int, ease_type: int):
	var config = _eyes._eye_configs[panel]
	var sh = config.shift_holder
	var base_x = config.base_center.x
	var from_x = _pending_eye_shift.get(panel, sh.rect_position.x - base_x)
	_tween.interpolate_property(sh, "rect_position:x",
		base_x + from_x, base_x + target_x, duration, trans, ease_type, delay)
	_pending_eye_shift[panel] = target_x

func _tween_eye_shift_y(panel: Panel, duration: float, delay: float, target_y: float, trans: int, ease_type: int):
	var config = _eyes._eye_configs[panel]
	var sh = config.shift_holder
	var base_y = config.base_center.y
	var from_y = _pending_eye_shift_y.get(panel, sh.rect_position.y - base_y)
	_tween.interpolate_property(sh, "rect_position:y",
		base_y + from_y, base_y + target_y, duration, trans, ease_type, delay)
	_pending_eye_shift_y[panel] = target_y

# Scales each eye around its own center. Runs on osh.rect_scale.
func _tween_eye_scale(panel: Panel, duration: float, delay: float, target_s: float, trans: int, ease_type: int):
	var osh = _eyes._eye_configs[panel].osh
	var from_s = _pending_eye_own_scale.get(panel, osh.rect_scale.x)
	_tween.interpolate_property(osh, "rect_scale",
		Vector2(from_s, from_s), Vector2(target_s, target_s), duration, trans, ease_type, delay)
	_pending_eye_own_scale[panel] = target_s

# Scales each eye around the shared midpoint. Runs on csh.rect_scale + csh.rect_position:x.
# These properties are separate from shift_holder and osh, so all four effects run in parallel.
func _tween_eye_center_scale(panel: Panel, duration: float, delay: float, target_s: float, trans: int, ease_type: int):
	var config = _eyes._eye_configs[panel]
	var csh = config.csh
	var base_x = config.base_center.x
	var from_s = _pending_eye_center_scale.get(panel, csh.rect_scale.x)
	_tween.interpolate_property(csh, "rect_scale",
		Vector2(from_s, from_s), Vector2(target_s, target_s), duration, trans, ease_type, delay)
	_tween.interpolate_property(csh, "rect_position:x",
		(base_x - _eyes._eye_common_x) * (from_s - 1.0),
		(base_x - _eyes._eye_common_x) * (target_s - 1.0),
		duration, trans, ease_type, delay)
	_pending_eye_center_scale[panel] = target_s

func close_clock(duration: float, delay: float, target: float = 0.0,
				 trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_scale_y(_hours_label, duration, delay, target, trans, ease_type)
	_tween_scale_y(_minutes_label, duration, delay, target, trans, ease_type)

func open_clock(duration: float, delay: float, target: float = 1.0,
				trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_scale_y(_hours_label, duration, delay, target, trans, ease_type)
	_tween_scale_y(_minutes_label, duration, delay, target, trans, ease_type)

func open_left_eye(duration: float, delay: float, target: float = 1.0,
				   trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_y(_eyes.left_eye, duration, delay, target, trans, ease_type)

func close_left_eye(duration: float, delay: float, target: float = 0.0,
					trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_y(_eyes.left_eye, duration, delay, target, trans, ease_type)

func open_right_eye(duration: float, delay: float, target: float = 1.0,
					trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_y(_eyes.right_eye, duration, delay, target, trans, ease_type)

func close_right_eye(duration: float, delay: float, target: float = 0.0,
					 trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_y(_eyes.right_eye, duration, delay, target, trans, ease_type)

func open_both_eyes(duration: float, delay: float, target: float = 1.0,
					trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	open_left_eye(duration, delay, target, trans, ease_type)
	open_right_eye(duration, delay, target, trans, ease_type)

func close_both_eyes(duration: float, delay: float, target: float = 0.0,
					 trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	close_left_eye(duration, delay, target, trans, ease_type)
	close_right_eye(duration, delay, target, trans, ease_type)

func shift_left_eye(duration: float, delay: float, amount: float,
					trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_shift(_eyes.left_eye, duration, delay, amount, trans, ease_type)

func shift_right_eye(duration: float, delay: float, amount: float,
					 trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_shift(_eyes.right_eye, duration, delay, amount, trans, ease_type)

func shift_eyes(duration: float, delay: float, amount: float,
				trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	shift_left_eye(duration, delay, amount, trans, ease_type)
	shift_right_eye(duration, delay, amount, trans, ease_type)

func shift_left_eye_y(duration: float, delay: float, amount: float,
					  trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_shift_y(_eyes.left_eye, duration, delay, amount, trans, ease_type)

func shift_right_eye_y(duration: float, delay: float, amount: float,
					   trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_shift_y(_eyes.right_eye, duration, delay, amount, trans, ease_type)

func shift_eyes_y(duration: float, delay: float, amount: float,
				  trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	shift_left_eye_y(duration, delay, amount, trans, ease_type)
	shift_right_eye_y(duration, delay, amount, trans, ease_type)

func scale_left_eye(duration: float, delay: float, target: float,
					trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_scale(_eyes.left_eye, duration, delay, target, trans, ease_type)

func scale_right_eye(duration: float, delay: float, target: float,
					 trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_scale(_eyes.right_eye, duration, delay, target, trans, ease_type)

func scale_eyes(duration: float, delay: float, target: float,
				trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	scale_left_eye(duration, delay, target, trans, ease_type)
	scale_right_eye(duration, delay, target, trans, ease_type)

func scale_eyes_from_center(duration: float, delay: float, target: float,
							 trans: int = Tween.TRANS_SINE, ease_type: int = Tween.EASE_IN_OUT):
	_tween_eye_center_scale(_eyes.left_eye,  duration, delay, target, trans, ease_type)
	_tween_eye_center_scale(_eyes.right_eye, duration, delay, target, trans, ease_type)
