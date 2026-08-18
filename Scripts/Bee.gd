@tool
extends Node2D

@export var body: Node2D
@export var states: BeeStateMachine
@export var mover: BeeMover
@export var animator: BeeAnimator
@export var wave: BeeWave

@export var base_speed: float = 40.0
@export var speed_amp: float = 23.0
@export var speed_freq: float = 0.5
@export var wave_amp: float = 3.0
@export var wave_freq: float = 3.0

@export var chase_radius: float = 140.0:
	set(value):
		chase_radius = value
		queue_redraw()
@export var chase_exit_radius: float = 170.0:
	set(value):
		chase_exit_radius = value
		queue_redraw()
@export var chase_speed: float = 80.0
@export var chase_speed_freq: float = 3
@export var chase_stop_distance: float = 48.0
@export var chase_wave_amp: float = 2.0
@export var chase_wave_freq: float = 3.0
@export var chase_delay: float = 3.0
@export var turn_duration: float = 0.7

var _noise := FastNoiseLite.new()
var _time: float
var _chase_time: float
var _turn_time: float
var _turn_length: float
var _pending_forward: bool
var _did_flip: bool


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	_noise.seed = randi()
	_noise.frequency = 0.4
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	body.position = Vector2.ZERO
	mover.setup()
	if not mover.reached_path_end.is_connected(_on_reached_path_end):
		mover.reached_path_end.connect(_on_reached_path_end)
	if not animator.clip_ended.is_connected(_on_clip_ended):
		animator.clip_ended.connect(_on_clip_ended)
	_enter_fly()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_update_state()
	match states.current:
		BeeStateMachine.State.TURN:
			_tick_turn(delta)
		BeeStateMachine.State.CHASE:
			_chase_time += delta
			if _chase_time >= chase_delay:
				mover.tick_chase(delta, chase_speed + sin(_chase_time * speed_freq), chase_stop_distance)
		_:
			var speed := base_speed + sin(_time * speed_freq) * speed_amp
			mover.tick_path(delta, speed)
	_update_wave(delta)
	queue_redraw()


func _update_state() -> void:
	if states.is_turn():
		return
	var dist := global_position.distance_to(get_global_mouse_position())
	if states.is_fly() and dist < chase_radius and not mover.is_near_path_end():
		_enter_chase()
	elif states.is_chase() and dist > chase_exit_radius:
		mover.snap_to_path()
		_enter_fly()


func _update_wave(delta: float) -> void:
	var amp := chase_wave_amp if states.is_chase() else wave_amp
	var freq := chase_wave_freq if states.is_chase() else wave_freq
	if states.is_chase() && _chase_time < chase_delay:
		freq *= 1.2
	wave.tick(delta, amp, freq)


func _enter_fly() -> void:
	states.set_state(BeeStateMachine.State.FLY)
	animator.play_fly()


func _enter_chase() -> void:
	_chase_time = 0
	states.set_state(BeeStateMachine.State.CHASE)
	animator.play_chase()


func _on_reached_path_end(going_forward_after: bool) -> void:
	_enter_turn(going_forward_after)


func _enter_turn(going_forward_after: bool) -> void:
	states.set_state(BeeStateMachine.State.TURN)
	_turn_time = 0.0
	_did_flip = false
	_pending_forward = going_forward_after
	_turn_length = maxf(animator.play_turn(), turn_duration)


func _tick_turn(delta: float) -> void:
	_turn_time += delta
	if _turn_time >= _turn_length:
		_finish_turn()


func _on_clip_ended(clip_name: String) -> void:
	if states.is_turn() and clip_name == animator.turn_clip:
		_finish_turn()


func _finish_turn() -> void:
	if not states.is_turn():
		return
	if not _did_flip:
		_did_flip = true
		mover.apply_turn(_pending_forward)
	_enter_fly()


func _draw() -> void:
	if mover == null:
		return
	var from := to_local(mover.start_pos)
	var to := to_local(mover.end_pos)
	draw_line(from, to, Color.CADET_BLUE, 2.0)
	draw_circle(from, 4.0, Color.YELLOW)
	draw_circle(to, 4.0, Color.YELLOW)
	draw_arc(Vector2.ZERO, chase_radius, 0.0, TAU, 48, Color(1.0, 0.45, 0.2, 0.7), 2.0)
	draw_arc(Vector2.ZERO, chase_exit_radius, 0.0, TAU, 48, Color(0.3, 0.8, 1.0, 0.45), 1.5)
