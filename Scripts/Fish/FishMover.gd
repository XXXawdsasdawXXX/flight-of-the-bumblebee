class_name FishMover
extends Node

@export var animation: FishAnimator
@export var body: Node2D
@export var speed: float = 80
@export var bob_amp: float = 10
@export var bob_freq: float = 2

var _dir: float = 1
var _base_y: float = 0
var _time: float = 0; 
var _target: Vector2
var _move_right: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_base_y = body.position.y
	_set_target()
	animation.play_swim()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_time += delta
	body.position.x += _dir * speed * delta
	
	if _move_right and body.position.x >= _target.x:
		_set_target()
	elif not _move_right and body.position.x <= _target.x:
		_set_target()


func _set_target() -> void:
	var size := get_viewport().get_visible_rect().size
	var margin := 40.0
	_target = Vector2(randf_range(margin, size.x - margin), _base_y)
	_move_right = body.position.x < _target.x 
	_dir = 1 if _move_right else -1
