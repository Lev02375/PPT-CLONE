extends CanvasLayer

@onready var left_stick = $LeftJoystick/Stick
@onready var left_base = $LeftJoystick/Base
@onready var right_stick = $RightJoystick/Stick
@onready var right_base = $RightJoystick/Base

var left_active: bool = false
var right_active: bool = false
var left_touch_idx: int = -1
var right_touch_idx: int = -1

func _ready():
	left_base.visible = false
	right_base.visible = false

func _input(event):
	if event is InputEventScreenTouch:
		var screen_size = get_viewport().get_visible_rect().size
		if event.pressed:
			if event.position.x < screen_size.x / 2 and not left_active:
				left_active = true
				left_touch_idx = event.index
				left_base.position = event.position
				left_base.visible = true
				left_stick.position = Vector2.ZERO
			elif event.position.x >= screen_size.x / 2 and not right_active:
				right_active = true
				right_touch_idx = event.index
				right_base.position = event.position
				right_base.visible = true
				right_stick.position = Vector2.ZERO
		else:
			if event.index == left_touch_idx:
				left_active = false
				left_base.visible = false
				left_touch_idx = -1
			if event.index == right_touch_idx:
				right_active = false
				right_base.visible = false
				right_touch_idx = -1

	if event is InputEventScreenDrag:
		if event.index == left_touch_idx:
			var offset = event.position - left_base.position
			var max_dist = 40
			if offset.length() > max_dist:
				offset = offset.normalized() * max_dist
			left_stick.position = offset
		elif event.index == right_touch_idx:
			var offset = event.position - right_base.position
			var max_dist = 40
			if offset.length() > max_dist:
				offset = offset.normalized() * max_dist
			right_stick.position = offset
