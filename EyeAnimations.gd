extends Node

var _tween: Tween
var _tweener  # EyeTweener node

func setup(tween: Tween, tweener):
	_tween   = tween
	_tweener = tweener

func play_peek():
	_tween.stop_all()
	_tweener.reset_pending()
	_tweener.close_clock(0.1, 0.0)
	
	_tweener.open_both_eyes(0.05, 0.05, 0.1)
	_tweener.scale_eyes(0.01, 0, 1.2)
	
	_tweener.scale_left_eye(0.3, 1.5, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tweener.open_left_eye(0.3, 1.5, 0.3, Tween.TRANS_QUART, Tween.EASE_OUT)
	
	_tweener.open_left_eye(0.1, 2.9, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tweener.shift_eyes(0.3, 3, -80)
	_tweener.open_left_eye(0.3, 3, 0.6, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tweener.open_right_eye(0.3, 3, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	
	_tweener.scale_right_eye(0.2, 5, 1, Tween.TRANS_QUART, Tween.EASE_OUT)
	_tweener.open_both_eyes(0.2, 5, 0.8, Tween.TRANS_QUART)
	_tweener.shift_eyes(0.1, 5, 60, Tween.TRANS_QUART, Tween.EASE_OUT)
	
	_tweener.open_both_eyes(0.1, 6, 1, Tween.TRANS_QUART)
	_tweener.shift_eyes(0.1, 6, 0, Tween.TRANS_QUART, Tween.EASE_OUT)
	
	_tweener.close_both_eyes(0.1, 7.7)
	_tweener.open_both_eyes(0.1, 7.8)
	_tweener.close_both_eyes(0.1, 7.9)
	_tweener.open_clock(0.1, 8)

	_tween.start()

func play_happy():
	_tween.stop_all()
	_tweener.reset_pending()
	_tweener.close_clock(0.1, 0.0)
	_tweener.open_both_eyes(0.1, 0.1)
	_tweener.scale_eyes(0.4, 0.4, 1.4, Tween.TRANS_QUART, Tween.EASE_OUT)
	_tweener.scale_eyes_from_center(0.4, 0.4, 1.2, Tween.TRANS_QUART, Tween.EASE_OUT)
	_tweener.open_both_eyes(0.4, 0.4, 0.2, Tween.TRANS_QUART, Tween.EASE_OUT)
	_tweener.shift_eyes_y(0.8, 0.4, -140, Tween.TRANS_QUART, Tween.EASE_OUT)
	_tweener.scale_eyes(0.3, 2, 1, Tween.TRANS_QUART, Tween.EASE_OUT)
	_tweener.scale_eyes_from_center(0.3, 2, 1, Tween.TRANS_QUART, Tween.EASE_OUT)
	_tweener.open_both_eyes(0.3, 2, 1, Tween.TRANS_QUART, Tween.EASE_OUT)
	_tweener.shift_eyes_y(0.3, 1.95, 0, Tween.TRANS_QUART, Tween.EASE_OUT)
	_tweener.close_both_eyes(0.1, 3)
	_tweener.open_clock(0.1, 3.1)
	_tween.start()
