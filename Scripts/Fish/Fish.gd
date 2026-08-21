@tool
extends Node2D

enum State { SWIM, AGR, FLY }

@export var player: Node2D
@export var animator: FishAnimator
@export var mover: FishMover
@export var see_range: float = 60 
@export var above: float = 100

var state: State 
var _wait: float = 0
var _peak: Vector2


func _ready() -> void:
	_enter_swim()


func _process(delta: float) -> void:
	if state == State.SWIM:
		mover.tick(delta)
		if _can_see_player():
			_enter_agr()
	elif state == State.AGR:
		if _wait > 0:
			_wait -= delta
			if _wait <= 0:
				animator.play_start_fly()
			return
		_peak.x = player.global_position.x
		if mover.tick_to(_peak, delta):
			print("долетела")
	
	
func _can_see_player() -> bool:
	return absf(global_position.x - player.global_position.x) < see_range  

	
func _enter_swim() -> void:
	state = State.SWIM
	animator.play_swim()


func _enter_agr() -> void:
	state = State.AGR
	_wait = animator.play_agr()


func _enter_fly_up() -> void:
	state = State.FLY
	_peak = Vector2(player.global_position.x, player.global_position.y - above)
	_wait = animator.play_start_fly()	

func _draw() -> void:
	draw_arc(Vector2.ZERO, see_range, 0.0, TAU, 48, Color.YELLOW)
