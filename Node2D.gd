extends Node2D

class FontEntry:
	var path: String
	var size: int
	var date_size: int
	func _init(p: String, s: int, ds: int) -> void:
		path = p
		size = s
		date_size = ds

const _FONT_TABLE: Array = [
	["BarlowCondensed-ExtraBoldItalic.ttf", 480, 56],
	["FiraSans-Ultra.ttf",                  360, 48],
	["Fraunces_72pt-Black.ttf",             360, 48],
	["Fraunces_72pt_Soft-Bold.ttf",         360, 44],
	["Fredoka-Bold.ttf",                    400, 52],
	["Righteous-Regular.ttf",               380, 48],
	["Unbounded-Black.ttf",                 260, 36],
]
const DEFAULT_FONT_SIZE: int = 412
const DEFAULT_DATE_FONT_SIZE: int = 44

const SETTINGS_PATH = "user://settings.cfg"

const EXIT_BUTTON = 8
const A_BUTTON = 1
const B_BUTTON = 0
const Y_BUTTON = 2
const X_BUTTON = 3
const L1_BUTTON = 4
const L2_BUTTON = 5
const SELECT_BUTTON = 6
const DPAD_UP    = 12
const DPAD_DOWN  = 13
const DPAD_LEFT  = 14
const DPAD_RIGHT = 15

const N_DATE_FORMATS    = 4
const DATE_TOTAL_STATES = 1 + N_DATE_FORMATS * 2   # = 9
const DATE_LABEL_HEIGHT = 50.0

const MONTH_NAMES: Array  = ["January","February","March","April","May","June",
							  "July","August","September","October","November","December"]
const MONTH_SHORT: Array  = ["Jan","Feb","Mar","Apr","May","Jun",
							  "Jul","Aug","Sep","Oct","Nov","Dec"]
const WEEKDAY_NAMES: Array = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
const WEEKDAY_SHORT: Array = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

onready var log_label       = $Log
onready var clock_label     = $Clock
onready var _test_bg         = $TestBG
onready var _font_info      = $FontInfo
onready var _tween          = $Tween
onready var _eyes           = $Eyes
onready var _eye_tweener    = $EyeTweener
onready var _eye_animations = $EyeAnimations
onready var _date_label     = $Date

var quitting    = false
var last_second = -1

var _fonts: Array      = []
var _font_index: int   = 0
var _clock_font: DynamicFont
var _date_font: DynamicFont
var _date_state: int   = 0
var _animations: Array = []
#var _debug_clock_rect: Label

func _ready():
	log_label.visible = false
	log_label.add_text("Ready — press any key\n")
	clock_label.rect_pivot_offset = clock_label.rect_size / 2
	_eye_tweener.setup(_tween, _eyes, clock_label, _date_label)
	_eye_animations.setup(_tween, _eye_tweener)
	_animations = [
		funcref(_eye_animations, "play_peek"),
		funcref(_eye_animations, "play_happy"),
		funcref(_eye_animations, "play_follow"),
	]
	_scan_fonts()
	_clock_font = DynamicFont.new()
	_date_font = DynamicFont.new()
	_date_font.size = DEFAULT_DATE_FONT_SIZE
	_date_label.set("custom_fonts/font", _date_font)
	
#	var _debug_border = StyleBoxFlat.new()
#	_debug_border.bg_color = Color(0, 0, 0, 0)
#	_debug_border.border_color = Color(1, 0, 0, 1)
#	_debug_border.set_border_width_all(2)
#	_date_label.add_stylebox_override("normal", _debug_border)
##	_debug_clock_rect = Label.new()
#	var _debug_clock_border = StyleBoxFlat.new()
#	_debug_clock_border.bg_color = Color(0, 0, 0, 0)
#	_debug_clock_border.border_color = Color(0, 1, 0, 1)
#	_debug_clock_border.set_border_width_all(2)
#	_debug_clock_rect.add_stylebox_override("normal", _debug_clock_border)	
#	add_child(_debug_clock_rect)

	if _fonts.size() > 0:
		_font_index = _load_font_index_from_settings()
		_date_state = _load_date_state_from_settings()
		_apply_font(_font_index)
	clock_label.set("custom_fonts/font", _clock_font)
	clock_label.rect_scale = Vector2(1, 0)
	_date_label.modulate.a = 0
	_apply_date_state()
	_eye_animations.play_boot()

func _process(_delta):
	var time = OS.get_time()
	if Input.is_key_pressed(KEY_SPACE) || Input.is_joy_button_pressed(0, L1_BUTTON):
		clock_label.text = "8888"
		_font_info.visible = true
		_test_bg.visible = true
	elif time.second != last_second:
		last_second = time.second
		clock_label.text = "%02d%02d" % [time.hour, time.minute]
		_update_date_text()
		_font_info.visible = false
		if time.second == 58 and randi() % 15 == 0:
			var fn = _animations[randi() % _animations.size()]
			fn.call_func()
	else:
		_font_info.visible = false
		_test_bg.visible = false

func _input(event):
	_print_input(event)
	if _isKeyOrButton(event, KEY_A, EXIT_BUTTON):
		_quit()
	elif _isKeyOrButton(event, KEY_B, A_BUTTON):
		_eye_animations.play_peek()
	elif _isKeyOrButton(event, KEY_C, B_BUTTON):
		_eye_animations.play_happy()
	elif _isKeyOrButton(event, KEY_V, Y_BUTTON):
		_eye_animations.play_follow()
	elif _isKeyOrButton(event, KEY_S, SELECT_BUTTON):
		log_label.visible = !log_label.visible
	elif _isKeyOrButton(event, KEY_UP, DPAD_UP):
		if _fonts.size() > 0:
			_font_index = (_font_index - 1 + _fonts.size()) % _fonts.size()
			_apply_font(_font_index)
			_save_settings()
	elif _isKeyOrButton(event, KEY_DOWN, DPAD_DOWN):
		if _fonts.size() > 0:
			_font_index = (_font_index + 1) % _fonts.size()
			_apply_font(_font_index)
			_save_settings()
	elif _isKeyOrButton(event, KEY_LEFT, DPAD_LEFT):
		_date_state = (_date_state - 1 + DATE_TOTAL_STATES) % DATE_TOTAL_STATES
		_apply_date_state()
		_save_settings()
	elif _isKeyOrButton(event, KEY_RIGHT, DPAD_RIGHT):
		_date_state = (_date_state + 1) % DATE_TOTAL_STATES
		_apply_date_state()
		_save_settings()

func _save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("display", "font_name", _fonts[_font_index].path.get_file())
	cfg.set_value("display", "date_state", _date_state)
	cfg.save(SETTINGS_PATH)

func _load_font_index_from_settings() -> int:
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return 0
	var saved_name = cfg.get_value("display", "font_name", "")
	for i in range(_fonts.size()):
		if _fonts[i].path.get_file() == saved_name:
			return i
	return 0

func _load_date_state_from_settings() -> int:
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK: return 0
	var s = cfg.get_value("display", "date_state", 0)
	return s if s >= 0 and s < DATE_TOTAL_STATES else 0

func _scan_fonts():
	var size_lookup: Dictionary = {}
	var date_size_lookup: Dictionary = {}
	for row in _FONT_TABLE:
		size_lookup[row[0]] = row[1]
		date_size_lookup[row[0]] = row[2]

	var dir = Directory.new()
	if dir.open("res://fonts") != OK:
		return
	dir.list_dir_begin(true, true)
	var file = dir.get_next()
	while file != "":
		var lower = file.to_lower()
		if lower.ends_with(".ttf") or lower.ends_with(".otf"):
			var entry = FontEntry.new(
				"res://fonts/" + file,
				size_lookup.get(file, DEFAULT_FONT_SIZE),
				date_size_lookup.get(file, DEFAULT_DATE_FONT_SIZE))
			_fonts.append(entry)
		file = dir.get_next()
	dir.list_dir_end()
	_fonts.sort_custom(self, "_sort_fonts")

func _sort_fonts(a: FontEntry, b: FontEntry) -> bool:
	return a.path < b.path

func _apply_font(index: int):
	var entry: FontEntry = _fonts[index]
	var fd = DynamicFontData.new()
	fd.font_path = entry.path
	_clock_font.font_data = fd
	_clock_font.size = entry.size
	_date_font.font_data = fd
	_date_font.size = entry.date_size
	_font_info.text = entry.path.get_file()
	log_label.add_text("Font: " + entry.path.get_file() + " (" + str(entry.size) + ")\n")
	_apply_date_state()

func _apply_date_state():
	var visible = _date_state != 0
	_date_label.visible = visible
	var text_sz = _clock_font.get_string_size("0000")
	var clock_center_x = 1024.0 / 2.0
	var clock_center_y = 768.0 / 2.0
#	_debug_clock_rect.margin_left   = clock_center_x - text_sz.x / 2.0
#	_debug_clock_rect.margin_right  = clock_center_x + text_sz.x / 2.0
#	_debug_clock_rect.margin_top    = clock_center_y - text_sz.y / 2.0
#	_debug_clock_rect.margin_bottom = clock_center_y + text_sz.y / 2.0
	if not visible:
		return
	var text_height = text_sz.y
	var at_top = _date_state >= 1 and _date_state <= N_DATE_FORMATS
	if at_top:
		var text_top = clock_center_y - text_height / 2.0
		_date_label.margin_bottom = text_top + 40
		_date_label.margin_top    = _date_label.margin_bottom - DATE_LABEL_HEIGHT
		_date_label.valign = Label.VALIGN_BOTTOM
	else:
		var text_bottom = clock_center_y + text_height / 2.0
		_date_label.margin_top    = text_bottom - 40
		_date_label.margin_bottom = _date_label.margin_top + DATE_LABEL_HEIGHT
		_date_label.valign = Label.VALIGN_TOP
	_update_date_text()


func _ordinal(n: int) -> String:
	if n in [11, 12, 13]: return str(n) + "th"
	match n % 10:
		1: return str(n) + "st"
		2: return str(n) + "nd"
		3: return str(n) + "rd"
	return str(n) + "th"

func _update_date_text():
	if _date_state == 0: return
	var d = OS.get_date()
	var fmt = (_date_state - 1) % N_DATE_FORMATS
	match fmt:
		0: _date_label.text = WEEKDAY_NAMES[d.weekday]
		1: _date_label.text = WEEKDAY_SHORT[d.weekday] + " " + str(d.day) + " " + MONTH_SHORT[d.month - 1]
		2: _date_label.text = WEEKDAY_NAMES[d.weekday] + " " + _ordinal(d.day) + " " + MONTH_NAMES[d.month - 1]
		3: _date_label.text = "%02d / %02d / %d" % [d.day, d.month, d.year]

func _quit():
	if not quitting:
		quitting = true
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
