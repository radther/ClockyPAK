extends Node2D

var left_eye: Panel
var right_eye: Panel
var _eye_configs: Dictionary = {}
var _eye_common_x: float = 0.0

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
	left_eye  = _make_eye(Vector2(342, 384))
	right_eye = _make_eye(Vector2(684, 384))
	_eye_common_x = (_eye_configs[left_eye].base_center.x +
	                 _eye_configs[right_eye].base_center.x) / 2.0
