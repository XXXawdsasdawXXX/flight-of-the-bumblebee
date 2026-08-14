extends Node2D

@export var bone0: Bone2D
@export var bone1: Bone2D
@export var bone2: Bone2D
@export var drag: float = 0.05
@export var max_angle: float = 0.6 # радианы -35 градусов
@export var follow: float = 10
@export var max_bone_delta: float = 0.35 # -20 градусов

var _prev_global: Vector2
var _angle0: float
var _angle1: float
var _angle2: float


func _ready() -> void:
	_prev_global = global_position
	
func _process(delta: float) -> void:
	var velocity :Vector2 = (global_position - _prev_global) / maxf(delta, 0.0001)
	_prev_global = global_position

	var target := clampf(velocity.x * drag, -max_angle, max_angle)
	
	_angle0 = lerp_angle(_angle1, target * 0.45, 1 - exp(-follow * delta))
	_angle1 = lerp_angle(_angle1, target * 1.2 , 1 - exp(-follow * delta))
	_angle2 = lerp_angle(_angle2, target * 1.8 , 1 - exp(-follow * delta))

	# после расчёта углов:
	_angle2 = clampf(_angle2, _angle0 - max_bone_delta * 2.0, _angle0 + max_bone_delta * 2.0)
	# ещё надёжнее — относительно bone1:
	_angle2 = clampf(_angle2, _angle1 - max_bone_delta, _angle1 + max_bone_delta)

	bone0.rotation = _angle0
	bone1.rotation = _angle1
	bone2.rotation = _angle2
