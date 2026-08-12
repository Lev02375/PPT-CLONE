extends CharacterBody3D

@export var patrol_speed: float = 2.0
@export var chase_speed: float = 5.5
@export var detection_range: float = 15.0
@export var attack_range: float = 1.5
@export var lose_interest_distance: float = 25.0

@onready var player: Node3D
@onready var raycast = $RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var mesh = $MeshInstance3D
@onready var eyes = $Eyes

enum State { PATROL, CHASE, SEARCH }
var current_state = State.PATROL
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var search_timer: float = 0.0
var last_known_player_pos: Vector3

func _ready():
	player = get_tree().get_first_node_in_group("player")
	_generate_patrol_points()
	# Set eyes to glow red
	if eyes:
		var mat = StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color(1, 0, 0)
		mat.emission_energy = 2.0
		eyes.material_override = mat

func _generate_patrol_points():
	# Generate random patrol points around spawn
	var base_pos = global_position
	for i in range(4):
		var angle = i * PI / 2
		var point = base_pos + Vector3(cos(angle) * 8, 0, sin(angle) * 8)
		patrol_points.append(point)

func _physics_process(delta):
	if not player:
		return

	var dist_to_player = global_position.distance_to(player.global_position)
	var can_see_player = _can_see_player()

	match current_state:
		State.PATROL:
			if can_see_player and dist_to_player < detection_range:
				current_state = State.CHASE
				_play_chase_sound()
			else:
				_patrol(delta)

		State.CHASE:
			if dist_to_player > lose_interest_distance:
				current_state = State.SEARCH
				last_known_player_pos = player.global_position
				search_timer = 5.0
			elif dist_to_player < attack_range:
				_attack_player()
			else:
				_chase_player(delta)

		State.SEARCH:
			search_timer -= delta
			if can_see_player and dist_to_player < detection_range:
				current_state = State.CHASE
			elif search_timer <= 0:
				current_state = State.PATROL
			else:
				_search(delta)

	# Bobbing animation
	mesh.position.y = 1.0 + sin(Time.get_time_dict_from_system()["second"] * 5) * 0.1

func _can_see_player() -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 1.5,
		player.global_position + Vector3.UP * 1.5
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return false
	return result.collider == player

func _patrol(delta):
	if patrol_points.is_empty():
		return

	var target = patrol_points[current_patrol_index]
	var dir = (target - global_position).normalized()
	dir.y = 0

	velocity.x = dir.x * patrol_speed
	velocity.z = dir.z * patrol_speed

	if global_position.distance_to(target) < 1.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

	look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
	move_and_slide()

func _chase_player(delta):
	var dir = (player.global_position - global_position).normalized()
	dir.y = 0

	velocity.x = dir.x * chase_speed
	velocity.z = dir.z * chase_speed

	look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
	move_and_slide()

func _search(delta):
	var dir = (last_known_player_pos - global_position).normalized()
	dir.y = 0

	velocity.x = dir.x * patrol_speed
	velocity.z = dir.z * patrol_speed

	if global_position.distance_to(last_known_player_pos) < 1.0:
		velocity = Vector3.ZERO

	move_and_slide()

func _attack_player():
	if player and player.has_method("lose_game"):
		player.lose_game()
	velocity = Vector3.ZERO

func _play_chase_sound():
	# Optional: add AudioStreamPlayer3D with scary sound
	pass
