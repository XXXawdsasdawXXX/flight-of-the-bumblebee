@tool
extends Node2D

enum State { SWIM, AGR }

@export var player: Node2D
@export var animator: FishAnimator
@export var mover: FishMover
@export var see_range: float = 60 

var state: State 

func _ready() -> void:
	_enter_swim()


func _process(delta: float) -> void:
	if state == State.SWIM:
		mover.tick(delta)
		if _can_see_player():
			_enter_agr()
	
	
func _can_see_player() -> bool:
	return absf(global_position.x - player.global_position.x) < see_range  


func _enter_agr() -> void:
	state = State.AGR
	animator.play_agr()
	
	
func _enter_swim() -> void:
	state = State.SWIM
	animator.play_swim()


func _draw() -> void:
	draw_arc(Vector2.ZERO, see_range, 0.0, TAU, 48, Color.YELLOW)
