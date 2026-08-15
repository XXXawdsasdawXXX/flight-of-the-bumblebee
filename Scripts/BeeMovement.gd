@tool
extends Node2D

@export var body: Node2D
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
var _path_lenght: float


func  _ready() -> void:
	queue_redraw()
	
	if Engine.is_editor_hint():
		return
	
	_path_lenght = start_pos.distance_to(end_pos)
	position = start_pos
	body.position = Vector2.ZERO
	_flip_body()
	
	_noise.seed = randi()
	_noise.frequency = 0.4
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_time += delta
	_move(delta)
	queue_redraw()


func _move(delta: float) -> void:
	if _path_lenght < 0.001:
		return
	
	var current_speed := base_speed + sin(_time * speed_freq) * speed_amp
	var step := (current_speed * delta) / _path_lenght
	
	if _is_going_forward:
		_way_progress += step
		if _way_progress >= 1:
			_way_progress = 1
			_is_going_forward = false
			_flip_body()
			_update_target_position()
	else:
		_way_progress -= step
		if _way_progress <= 0:
			_way_progress = 0
			_is_going_forward = true
			_flip_body()
			_update_target_position()

		
	var point := start_pos.lerp(end_pos, _way_progress)
	position = point	
	body.position = Vector2(0, _noise.get_noise_1d(_time) * wave_amp)


func _update_target_position() -> void:
	var size = get_viewport().get_visible_rect().size.y
	var margin := 40
	var new_y = randf_range(margin, size - margin)
	
	if _is_going_forward:
		end_pos.y = new_y
	else: 
		start_pos.y = new_y

	_path_lenght = start_pos.distance_to(end_pos)

func _flip_body() -> void:
	body.scale.x = 1.0 if not _is_going_forward else -1.0

func _draw() -> void:
	var from := to_local(start_pos)
	var to := to_local(end_pos)
	draw_line(from, to, Color.CADET_BLUE,2)
	draw_circle(from, 4, Color.YELLOW)	
	draw_circle(to, 4, Color.YELLOW)	
