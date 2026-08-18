@tool
extends Node2D

@export var body: Node2D
@export var states: BeeStateMachine
@export var mover: BeeMover
@export var animator: BeeAnimator
@export var wave: BeeWave
@export var angry: BeeAngry

var _turn_time: float = 0.0
var _turn_length: float = 0.0
var _pending_forward: bool = false
var _did_flip: bool = false


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
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

	if states.is_fly() and angry.can_enter():
		angry.begin()
	else:
		match states.current:
			BeeStateMachine.State.ANGRY:
				angry.tick(delta)
			BeeStateMachine.State.FLY:
				mover.tick_path(delta)
				wave.tick_fly(delta)
			BeeStateMachine.State.TURN:
				_tick_turn(delta)

	queue_redraw()


func _enter_fly() -> void:
	states.set_state(BeeStateMachine.State.FLY)
	animator.play_fly()


func _on_reached_path_end(going_forward_after: bool) -> void:
	_enter_turn(going_forward_after)


func _enter_turn(going_forward_after: bool) -> void:
	states.set_state(BeeStateMachine.State.TURN)
	_turn_time = 0.0
	_did_flip = false
	_pending_forward = going_forward_after
	_turn_length = animator.play_turn()


func _tick_turn(delta: float) -> void:
	_turn_time += delta
	if _turn_time >= _turn_length:
		_finish_turn()


func _on_clip_ended(clip_name: String) -> void:
	if angry != null:
		angry.on_clip_ended(clip_name)
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
	if angry != null:
		angry.draw_gizmo(self)
