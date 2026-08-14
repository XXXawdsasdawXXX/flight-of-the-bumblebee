@tool
extends Node2D

@export var base_speed: float = 120
@export var speed_amp: float = 40
@export var speed_freq: float = 1.5
@export var wave_amp: float = 8
@export var start_pos: Vector2:
	set(value):
		start_pos = value
		queue_redraw()
@export var end_pos: Vector2:
	set(value):
		end_pos = value
		queue_redraw()

var _noise := FastNoiseLite.new()
var _time: float 
var _way_progress: float # 0 - старт. 1 - конец
var _is_going_forward: bool


func  _ready() -> void:
	position = start_pos
	#boot noise
	_noise.seed = randi()
	_noise.frequency = 0.4
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

func _process(delta: float) -> void:
	_time += delta
	_move(delta)


func _move(delta: float) -> void:
	var path_len := end_pos.length()
	if path_len < 0.001:
		return
	
	var current_speed := base_speed + sin(_time * speed_freq) * speed_amp
	var step := (current_speed * delta) / path_len
	
	if _is_going_forward:
		_way_progress += step
		if _way_progress >= 1:
			_way_progress = 1
			_is_going_forward = false
	else:
		_way_progress -= step
		if _way_progress <= 0:
			_way_progress = 0
			_is_going_forward = true
		
	var point := start_pos.lerp(end_pos, _way_progress)
	position.x = point.x	
	position.y = point.x + _noise.get_noise_1d(_time) * wave_amp	


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(
			start_pos, 
			end_pos, 
			Color.CADET_BLUE, 
			2)
