class_name FishMover
extends Node

@export var animation: FishAnimator
@export var body: Node2D
@export var speed: float = 80
@export var bob_amp: float = 10
@export var bob_freq: float = 2
@export var jump_speed: float = 450.0

var _dir: float = 1
var _base_y: float = 0
var _time: float = 0; 
var _target: Vector2
var _move_right: bool


func _ready() -> void:
	_base_y = body.position.y


func tick(delta: float) -> void:
	_time += delta
	body.position.x += _dir * speed * delta
	if _move_right and body.position.x >= _target.x:
		set_target()
	elif not _move_right and body.position.x <= _target.x:
		set_target()


func tick_to(target: Vector2, delta: float) -> bool:
	body.global_position = body.global_position.move_toward(target, jump_speed * delta)
	_face_to(target.x)
	return body.global_position.distance_to(target) < 8.0


func set_target() -> void:
	var size := get_viewport().get_visible_rect().size
	var margin := 40.0
	_target = Vector2(randf_range(margin, size.x - margin), _base_y)
	_move_right = body.position.x < _target.x 
	_dir = 1 if _move_right else -1
	body.scale.x = absf(body.scale.x) * -_dir


func _face_to(x: float) -> void:
	_dir = 1.0 if body.global_position.x < x else -1.0
	body.scale.x = absf(body.scale.x) * -_dir
