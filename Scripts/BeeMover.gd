class_name BeeMover
extends Node

signal reached_path_end(going_forward_after: bool)

@export var actor: Node2D
@export var body: Node2D
@export var start_pos: Vector2 = Vector2(-50, 300)
@export var end_pos: Vector2 = Vector2(1200, 500)
@export var path_end_margin: float = 0.1

var going_forward: bool = true
var progress: float = 0.0
var _path_length: float = 0.0


func setup() -> void:
	_path_length = start_pos.distance_to(end_pos)
	actor.position = start_pos
	progress = 0.0
	going_forward = true
	face_travel_direction()


func tick_path(delta: float, speed: float) -> void:
	if _path_length < 0.001:
		return

	var step := (speed * delta) / _path_length

	if going_forward:
		progress += step
		if progress >= 1.0:
			progress = 1.0
			actor.position = actor.position.move_toward(end_pos, speed * delta)
			if actor.position.distance_to(end_pos) < 2.0:
				reached_path_end.emit(false)
			return
	else:
		progress -= step
		if progress <= 0.0:
			progress = 0.0
			actor.position = actor.position.move_toward(start_pos, speed * delta)
			if actor.position.distance_to(start_pos) < 2.0:
				reached_path_end.emit(true)
			return

	var target := start_pos.lerp(end_pos, progress)
	actor.position = actor.position.move_toward(target, speed * delta)


func tick_chase(delta: float, speed: float, stop_distance: float) -> void:
	var to_mouse := actor.get_global_mouse_position() - actor.global_position
	if to_mouse.length() <= stop_distance:
		return
	actor.position += to_mouse.normalized() * speed * delta
	face_world_x(to_mouse.x)


func is_near_path_end() -> bool:
	if going_forward:
		return progress >= 1.0 - path_end_margin
	return progress <= path_end_margin


func snap_to_path() -> void:
	var offset := end_pos - start_pos
	var len_sq := offset.length_squared()
	if len_sq < 0.001:
		progress = 0.0
		_path_length = 0.0
		return
	progress = clampf((actor.position - start_pos).dot(offset) / len_sq, 0.0, 1.0)
	_path_length = start_pos.distance_to(end_pos)
	going_forward = body.scale.x > 0.0


func apply_turn(going_forward_after: bool) -> void:
	going_forward = going_forward_after
	face_travel_direction()
	_randomize_next_end_y()


func face_travel_direction() -> void:
	body.scale.x = 1.0 if going_forward else -1.0


func face_world_x(dir_x: float) -> void:
	if absf(dir_x) < 8.0:
		return
	body.scale.x = 1.0 if dir_x > 0.0 else -1.0


func _randomize_next_end_y() -> void:
	var size := actor.get_viewport().get_visible_rect().size.y
	var margin := 40.0
	var new_y := randf_range(margin, size - margin)
	if going_forward:
		end_pos.y = new_y
	else:
		start_pos.y = new_y
	_path_length = start_pos.distance_to(end_pos)
