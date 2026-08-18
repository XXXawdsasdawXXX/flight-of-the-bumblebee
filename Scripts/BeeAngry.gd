class_name BeeAngry
extends Node

@export var actor: Node2D
@export var mover: BeeMover
@export var animator: BeeAnimator
@export var states: BeeStateMachine

@export var radius: float = 130.0:
	set(value):
		radius = value
		_queue_actor_redraw()
@export var exit_radius: float = 250.0:
	set(value):
		exit_radius = value
		_queue_actor_redraw()
@export var delay: float = 1.5
@export var duration: float = 2.0
@export var start_speed: float = 60.0
@export var max_speed: float = 210.0
@export var acceleration: float = 170.0
@export var speed_amp: float = 12.0
@export var speed_freq: float = 3.0
@export var wave_amp: float = 10.0
@export var wave_freq: float = 5.0
@export var catch_distance: float = 18.0
@export var release_distance: float = 24.0

var tracking_enabled: bool

var _time: float = 0.0
var _after_exit_time: float = 0.0
var _dir: Vector2 = Vector2.ZERO
var _waiting_exit: bool = false
var _current_speed: float = 0.0
var _catch_point: Vector2 = Vector2.ZERO
var _phase_time: float = 0.0
var _phase_timeout: float = 0.0

enum AngryPhase { DELAY, CHASE, CARRY_BIRD, LOST_BIRD, EXIT_STATIC }
var _phase: AngryPhase = AngryPhase.DELAY


func can_enter() -> bool:
	if not states.is_fly():
		return false
	if mover.is_near_path_end():
		return false
	return actor.global_position.distance_to(actor.get_global_mouse_position()) < radius


func begin() -> void:
	_time = 0.0
	_after_exit_time = 0.0
	_waiting_exit = false
	_current_speed = start_speed
	_phase = AngryPhase.DELAY
	_phase_time = 0.0
	_phase_timeout = 0.0
	var mouse := actor.get_global_mouse_position()
	_dir = (mouse - actor.global_position).normalized()
	if _dir.length_squared() < 0.001:
		_dir = Vector2.RIGHT
	states.set_state(BeeStateMachine.State.ANGRY)
	animator.play_angry()


func tick(delta: float) -> void:
	if not states.is_angry():
		return

	_time += delta
	_phase_time += delta

	if _phase == AngryPhase.DELAY && _time > delay:
		_phase = AngryPhase.CHASE

	if _phase == AngryPhase.CARRY_BIRD:
		var mouse_shift := actor.get_global_mouse_position().distance_to(_catch_point)
		if mouse_shift >= release_distance:
			_phase = AngryPhase.LOST_BIRD
			_phase_time = 0.0
			_phase_timeout = animator.play_lost_bird()
		
		elif _phase_timeout > 0 and _phase_time >= _phase_timeout:
			animator.play_bird_idle()
			_phase_timeout = 0	
		return

	if _phase == AngryPhase.LOST_BIRD:
		if _phase_time >= _phase_timeout:
			_finish()
		return
	
	if _phase == AngryPhase.CHASE and not _waiting_exit:
		_dir = (actor.get_global_mouse_position() - actor.global_position).normalized()

	if not _can_be_angry() and not _waiting_exit:
		_waiting_exit = true
		_after_exit_time = 0.0

	if _waiting_exit:
		_start_exit_static()
		_finish()
		return
		
	var multiplier : float = 0.05 if _phase == AngryPhase.DELAY or _waiting_exit else 1
	_current_speed = move_toward(_current_speed, max_speed, acceleration * delta)
	var move_speed := _current_speed + sin(_time * speed_freq) * speed_amp * multiplier
	var from := actor.global_position
	actor.position += _dir * move_speed * delta
	mover.face_direction(_dir, true)

	if _did_cross_target(from, actor.global_position):
		_phase = AngryPhase.CARRY_BIRD
		_phase_time = 0.0
		_phase_timeout = animator.play_take_bird()
		_catch_point = actor.get_global_mouse_position()


func _can_be_angry() -> bool:
	return actor.global_position.distance_to(actor.get_global_mouse_position()) < exit_radius


func _finish() -> void:
	mover.snap_to_path()
	states.set_state(BeeStateMachine.State.FLY)
	animator.play_fly()


func _start_exit_static() -> void:
	if _phase == AngryPhase.EXIT_STATIC:
		return
	_phase = AngryPhase.EXIT_STATIC
	_phase_time = 0.0
	_phase_timeout = animator.play_angry_exit()


func on_clip_ended(clip_name: String) -> void:
	if not states.is_angry():
		return
	print("animation is ended: " + clip_name)
	if _phase == AngryPhase.CARRY_BIRD and clip_name == animator.take_bird_clip:
		animator.play_bird_idle()
		print("play bird idle")
		return
	if _phase == AngryPhase.LOST_BIRD and clip_name == animator.lost_bird_clip:
		_start_exit_static()
		return
	if _phase == AngryPhase.EXIT_STATIC and clip_name == animator.angry_exit_clip:
		_finish()


func _did_cross_target(from: Vector2, to: Vector2) -> bool:
	var mouse := actor.get_global_mouse_position()
	if mouse.distance_to(to) <= catch_distance:
		return true
	var segment := to - from
	var len_sq := segment.length_squared()
	if len_sq < 0.001:
		return false
	var t := clampf((mouse - from).dot(segment) / len_sq, 0.0, 1.0)
	var closest := from + segment * t
	return mouse.distance_to(closest) <= catch_distance


func draw_gizmo(host: Node2D) -> void:
	host.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.45, 0.2, 0.7), 2.0)
	host.draw_arc(Vector2.ZERO, exit_radius, 0.0, TAU, 48, Color(0.3, 0.8, 1.0, 0.45), 1.5)


func _queue_actor_redraw() -> void:
	if actor is CanvasItem:
		actor.queue_redraw()
