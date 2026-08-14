extends AnimatedSprite2D
@export var start_animation: String = "fly"

func _ready() -> void:
	play(start_animation)
