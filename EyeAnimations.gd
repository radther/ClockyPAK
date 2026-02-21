extends Node

var _tween: Tween
var _tweener  # EyeTweener node

func setup(tween: Tween, tweener):
	_tween   = tween
	_tweener = tweener

func play_peek():
	yield(get_tree().create_timer(10.0), "timeout")
	_tween.stop_all()
	_tweener.reset_pending()
	_tweener.close_clock(0.1, 0.0)
	_tweener.open_left_eye(1, 0.3, 0.7, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tweener.open_both_eyes(0.3, 1.5, 1)
	_tweener.shift_eyes(0.1, 2.1, -40)
	_tweener.shift_eyes(0.2, 3.4, 70)
	_tweener.close_both_eyes(0.1, 3.3)
	_tweener.open_both_eyes(0.1, 3.4, 1)
	_tweener.shift_eyes(0.1, 5, 0)
	_tweener.close_both_eyes(0.1, 5.4)
	_tweener.open_both_eyes(0.1, 5.5, 1)
	_tweener.close_both_eyes(0.1, 5.6)
	_tweener.open_clock(0.1, 5.7)
	_tween.start()

func play_happy():
	_tween.stop_all()
	_tweener.reset_pending()
	_tweener.close_clock(0.1, 0.0)
	_tweener.open_both_eyes(0.1, 0.1)
	_tweener.scale_eyes(0.7, 0.4, 1.4, Tween.TRANS_QUART)
	_tweener.scale_eyes_from_center(0.7, 0.4, 1.2, Tween.TRANS_QUART)
	_tweener.open_both_eyes(0.7, 0.4, 0.2, Tween.TRANS_QUART)
	_tweener.shift_eyes_y(0.8, 0.4, -140, Tween.TRANS_QUART)
	_tweener.scale_eyes(0.7, 2, 1, Tween.TRANS_QUART)
	_tweener.scale_eyes_from_center(0.7, 2, 1, Tween.TRANS_QUART)
	_tweener.open_both_eyes(0.7, 2, 1, Tween.TRANS_QUART)
	_tweener.shift_eyes_y(0.7, 1.95, 0, Tween.TRANS_QUART)
	_tweener.close_both_eyes(0.1, 3)
	_tweener.open_clock(0.1, 3.1)
	_tween.start()
