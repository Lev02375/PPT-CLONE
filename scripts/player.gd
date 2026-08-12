extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var touch_sensitivity: float = 0.005

@onready var camera = $Camera3D
@onready var flashlight = $Camera3D/Flashlight
@onready var raycast = $Camera3D/RayCast3D
@onready var interact_label = $UI/InteractLabel
@onready var win_label = $UI/WinLabel
@onready var lose_label = $UI/LoseLabel
@onready var mobile_ui = $UI/MobileUI

var has_key: bool = false
var can_move: bool = true
var touch_points: Dictionary = {}
var left_touch_index: int = -1
var right_touch_index: int = -1
var left_touch_pos: Vector2
var right_touch_pos: Vector2

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interact_label.visible = false
	win_label.visible = false
	lose_label.visible = false

	# Show mobile UI only on Android
	if OS.get_name() == "Android":
		mobile_ui.visible = true
	else:
		mobile_ui.visible = false

func _input(event):
	if not can_move:
		return

	# Mouse look (desktop)
	if event is InputEventMouseMotion and OS.get_name() != "Android":
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	# Flashlight toggle
	if event.is_action_pressed("flashlight_toggle"):
		flashlight.visible = not flashlight.visible

	# Interact
	if event.is_action_pressed("interact"):
		try_interact()

func _unhandled_input(event):
	# Touch controls for mobile
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			_assign_touch_zones()
		else:
			touch_points.erase(event.index)
			if event.index == left_touch_index:
				left_touch_index = -1
			if event.index == right_touch_index:
				right_touch_index = -1

	if event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if event.index == right_touch_index:
			var delta = event.relative
			rotate_y(-delta.x * touch_sensitivity)
			camera.rotate_x(-delta.y * touch_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _assign_touch_zones():
	var screen_width = get_viewport().size.x
	for idx in touch_points.keys():
		if idx == left_touch_index or idx == right_touch_index:
			continue
		if touch_points[idx].x < screen_width / 2 and left_touch_index == -1:
			left_touch_index = idx
			left_touch_pos = touch_points[idx]
		elif touch_points[idx].x >= screen_width / 2 and right_touch_index == -1:
			right_touch_index = idx
			right_touch_pos = touch_points[idx]

func _physics_process(delta):
	if not can_move:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Movement input
	var input_dir = Vector3.ZERO

	if OS.get_name() == "Android" and left_touch_index != -1:
		# Mobile joystick
		var touch_pos = touch_points[left_touch_index]
		var joystick_center = left_touch_pos
		var offset = touch_pos - joystick_center
		var max_dist = 80.0
		if offset.length() > max_dist:
			offset = offset.normalized() * max_dist
		input_dir.x = offset.x / max_dist
		input_dir.z = offset.y / max_dist
	else:
		# Keyboard
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	check_interactable()

func check_interactable():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.is_in_group("interactable"):
			interact_label.visible = true
			interact_label.text = "[E] " + collider.interact_text
			return
	interact_label.visible = false

func try_interact():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.is_in_group("interactable"):
			collider.interact(self)

func collect_key():
	has_key = true
	$UI/KeyIcon.visible = true

func win_game():
	can_move = false
	win_label.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func lose_game():
	can_move = false
	lose_label.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_flashlight_button_pressed():
	flashlight.visible = not flashlight.visible

func _on_interact_button_pressed():
	try_interact()
