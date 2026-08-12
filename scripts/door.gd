extends StaticBody3D

@export var interact_text: String = "Открыть дверь"
@export var needs_key: bool = true

@onready var mesh = $MeshInstance3D
@onready var collision = $CollisionShape3D

var is_open: bool = false

func interact(player):
	if is_open:
		return

	if needs_key and not player.has_key:
		interact_text = "Нужен ключ!"
		return

	is_open = true
	interact_text = ""

	# Animate door opening
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", rotation.y + PI/2, 1.0)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Disable collision after animation
	tween.tween_callback(func():
		collision.disabled = true
		if player.has_method("win_game"):
			player.win_game()
	)
