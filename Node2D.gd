extends Node2D

class FontEntry:
	var path: String
	var size: int
	func _init(p: String, s: int) -> void:
		path = p
		size = s

const _FONT_TABLE: Array = [
	["BarlowCondensed-ExtraBoldItalic.ttf", 480],
	["FiraSans-Ultra.ttf",                  360],
	["Fraunces_72pt-Black.ttf",             360],
	["Fraunces_72pt_Soft-Bold.ttf",         360],
	["Fredoka-Bold.ttf",                    400],
	["Righteous-Regular.ttf",               380],
	["Unbounded-Black.ttf",                 260],
]
const DEFAULT_FONT_SIZE: int = 412

const EXIT_BUTTON = 8   # Adjust if your controller uses a different index

const A_BUTTON = 1
const B_BUTTON = 0
const Y_BUTTON = 2
const X_BUTTON = 3
const L1_BUTTON = 4
const L2_BUTTON = 5

const SELECT_BUTTON = 6  # Adjust if your controller uses a different index
const DPAD_UP   = 12
const DPAD_DOWN = 13

onready var log_label       = $Log
onready var clock_label     = $Clock
onready var _test_bg         = $TestBG
onready var _font_info      = $FontInfo
onready var _tween          = $Tween
onready var _eyes           = $Eyes
onready var _eye_tweener    = $EyeTweener
onready var _eye_animations = $EyeAnimations

var quitting    = false
var last_second = -1

var _fonts: Array      = []
var _font_index: int   = 0
var _clock_font: DynamicFont
var _animations: Array = []

func _ready():
	log_label.visible = false
	log_label.add_text("Ready — press any key\n")
	clock_label.rect_pivot_offset = clock_label.rect_size / 2
	_eye_tweener.setup(_tween, _eyes, clock_label)
	_eye_animations.setup(_tween, _eye_tweener)
	_animations = [
		funcref(_eye_animations, "play_peek"),
		funcref(_eye_animations, "play_happy"),
		funcref(_eye_animations, "play_follow"),
	]
	_scan_fonts()
	_clock_font = DynamicFont.new()
	if _fonts.size() > 0:
		_apply_font(0)
	clock_label.set("custom_fonts/font", _clock_font)
	clock_label.rect_scale = Vector2(1, 0)
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
	elif _isKeyOrButton(event, KEY_DOWN, DPAD_DOWN):
		if _fonts.size() > 0:
			_font_index = (_font_index + 1) % _fonts.size()
			_apply_font(_font_index)

func _scan_fonts():
	var size_lookup: Dictionary = {}
	for row in _FONT_TABLE:
		size_lookup[row[0]] = row[1]

	var dir = Directory.new()
	if dir.open("res://fonts") != OK:
		return
	dir.list_dir_begin(true, true)
	var file = dir.get_next()
	while file != "":
		var lower = file.to_lower()
		if lower.ends_with(".ttf") or lower.ends_with(".otf"):
			var entry = FontEntry.new("res://fonts/" + file,
									  size_lookup.get(file, DEFAULT_FONT_SIZE))
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
	_font_info.text = entry.path.get_file()
	log_label.add_text("Font: " + entry.path.get_file() + " (" + str(entry.size) + ")\n")

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
