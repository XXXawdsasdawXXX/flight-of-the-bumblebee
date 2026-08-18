class_name BeeMover
extends Node

signal reached_path_end(going_forward_after: bool)

@export var actor: Node2D
@export var body: Node2D
@export var animator: BeeAnimator
@export var start_pos: Vector2 = Vector2(-50, 300)
@export var end_pos: Vector2 = Vector2(1200, 500)
@export var path_end_margin: float = 0.1
@export var base_speed: float = 30.0
@export var speed_amp: float = 23.0
@export var speed_freq: float = 0.5

var going_forward: bool = true
var progress: float = 0.0
var _path_length: float = 0.0
var _path_time: float = 0.0
var _look_right: bool
var _pending_scale_right: bool
var _flip_after_turn: bool = false
var _turn_time: float = 0.0
var _turn_duration: float = 0.0


func setup() -> void:
	_path_length = start_pos.distance_to(end_pos)
	actor.position = start_pos
	progress = 0.0
	going_forward = true
	_path_time = 0.0
	if animator != null and not animator.clip_ended.is_connected(_on_animator_clip_ended):
		animator.clip_ended.connect(_on_animator_clip_ended)
	apply_turn(going_forward)


func tick_path(delta: float) -> void:
	if _path_length < 0.001:
		return

	_path_time += delta
	var speed := base_speed + sin(_path_time * speed_freq) * speed_amp
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
	going_forward = _look_right


func apply_turn(going_forward_after: bool) -> void:
	going_forward = going_forward_after
	face_direction(Vector2.RIGHT if going_forward else Vector2.LEFT, false)
	_randomize_next_end_y()


func face_direction(dir: Vector2, with_animation: bool = false) -> void:
	if absf(dir.x) < 0.001:
		return

	var look_right := dir.x > 0.0
	if look_right == _look_right:
		return

	_look_right = look_right
	if with_animation:
		if _flip_after_turn:
			_pending_scale_right = look_right
			return
		_pending_scale_right = look_right
		_flip_after_turn = true
		_turn_time = 0.0
		_turn_duration = animator.play_turn() * 0.46
		if _turn_duration <= 0.0:
			_finish_animated_turn()
		return

	_apply_body_scale(look_right)


func _process(delta: float) -> void:
	if not _flip_after_turn:
		return
	_turn_time += delta
	if _turn_time >= _turn_duration:
		_finish_animated_turn()


func _on_animator_clip_ended(clip_name: String) -> void:
	if _flip_after_turn and clip_name == animator.turn_clip:
		_finish_animated_turn()


func _finish_animated_turn() -> void:
	if not _flip_after_turn:
		return
	_flip_after_turn = false
	_apply_body_scale(_pending_scale_right)


func _apply_body_scale(look_right: bool) -> void:
	var mag := absf(body.scale.x)
	if mag < 0.001:
		mag = 1.0
	body.scale.x = mag if look_right else -mag

func _randomize_next_end_y() -> void:
	var size := actor.get_viewport().get_visible_rect().size.y
	var margin := 40.0
	var new_y := randf_range(margin, size - margin)
	if going_forward:
		end_pos.y = new_y
	else:
		start_pos.y = new_y
	_path_length = start_pos.distance_to(end_pos)
