extends PathFollow2D

@export var speed: float = 80.0
@export var body: AnimatedSprite2D


func _process(delta: float) -> void:
	var old_x := global_position.x
	_move(delta)
	_rotate(old_x)


func _rotate(old_x: float) -> void:
	var moved_right := global_position.x > old_x
	body.flip_h = moved_right


func _move(delta: float) -> void:
	progress += speed * delta
