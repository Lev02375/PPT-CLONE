extends Area3D

@export var interact_text: String = "Подобрать ключ"

@onready var mesh = $MeshInstance3D
@onready var light = $OmniLight3D

func _ready():
	body_entered.connect(_on_body_entered)
	# Spin animation
	var tween = create_tween().set_loops()
	tween.tween_property(mesh, "rotation:y", PI * 2, 2.0)

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("collect_key"):
		body.collect_key()
		queue_free()

func interact(player):
	if player.has_method("collect_key"):
		player.collect_key()
		queue_free()
