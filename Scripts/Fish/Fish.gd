@tool
extends Node2D

enum State { SWIM, AGR, FLY_UP, REVERSE, FLY_DOWN, EAT, LAND }

@export var player: Node2D
@export var animator: FishAnimator
@export var mover: FishMover
@export var see_range: float = 60 
@export var eat_range: float = 50 
@export var above: float = 100

var state: State 

var _wait: float = 0
var _peak: Vector2
var _water_y: float
var _fall_target: Vector2
var _ate: bool


func _ready() -> void:
	_water_y = global_position.y
	_enter_swim()


func _process(delta: float) -> void:
	if state == State.SWIM:
		mover.tick(delta)
		if _can_see_player():
			_enter_agr()
	
	elif state == State.AGR:
		_wait -= delta
		if _wait <= 0.0:
			_enter_fly_up()
			
	elif state == State.FLY_UP:
		if _wait > 0.0:
			_wait -= delta
			if _wait <= 0.0:
				animator.play_fly_up()
			return
		_peak.x = player.global_position.x
		_peak.y = player.global_position.y - above
		if mover.tick_to(_peak, delta):
			_enter_reverse()
	
	elif state == State.REVERSE:
		_wait -= delta
		if _wait <= 0:
			_enter_fly_down()
			
	elif state == State.FLY_DOWN:
		if not _ate and _can_eat_player():
			_enter_eat()
			return
		if mover.tick_to(_fall_target, delta):
			if _ate:
				_enter_land()
			else:	
				_enter_swim()

	elif state == State.EAT:
		_wait -= delta
		if _wait <= 0:
			_enter_fly_down()
			
	elif state == State.LAND:
		_wait -= delta
		if _wait <= 0:
			_enter_swim()
	

func _enter_land() -> void:
	state = State.LAND
	_wait = animator.play_land()
	

func _enter_swim() -> void:
	state = State.SWIM
	mover.set_target()
	animator.play_swim()
	_ate = false


func _enter_agr() -> void:
	state = State.AGR
	_wait = animator.play_agr()
	
	
func _enter_reverse() -> void:
	state = State.REVERSE
	_wait = animator.play_reverse()  
	
	
func _enter_eat() -> void:
	state = State.EAT
	_ate = true
	player.die()
	_wait = animator.play_eat()


func _enter_fly_down() -> void:
	state = State.FLY_DOWN
	_fall_target = Vector2(global_position.x, _water_y)	
	if _ate:
		animator.play_fly_down_close()
	else:
		animator.play_fly_down()


func _enter_fly_up() -> void:
	state = State.FLY_UP
	_peak = Vector2(player.global_position.x, player.global_position.y - above)
	mover.face_to(_peak.x)
	_wait = animator.play_start_fly()	


func _can_see_player() -> bool:
	if player == null or not player.alive:
		return false
	return absf(global_position.x - player.global_position.x) < see_range


func _can_eat_player() -> bool:
	if player == null or not player.alive:
		return false
	var dx := absf(global_position.x - player.global_position.x)
	var passed := global_position.y >= player.global_position.y
	return dx < eat_range and passed


func _draw() -> void:
	draw_arc(Vector2.ZERO, see_range, 0.0, TAU, 48, Color.YELLOW)
	draw_arc(Vector2.ZERO, eat_range, 0.0, TAU, 48, Color.RED)
