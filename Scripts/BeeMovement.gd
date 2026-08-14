@tool
extends Node2D

# movement
@export var base_speed: float = 120
@export var speed_amp: float = 40
@export var speed_freq: float = 1.5
@export var distance: float = 300

#wave
@export var wave_amp: float = 8

#runtime
var _pos_y: float
var _noise := FastNoiseLite.new()
var _time: float = 0


func  _ready() -> void:
	_pos_y = position.y
	_noise.seed = randi()
	_noise.frequency = 0.4
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

func _process(delta: float) -> void:
	_time += delta
	_move(delta)
	_immitade_wave()
	queue_redraw()


func _move(delta: float) -> void:
	var current_speed := base_speed + sin(_time * speed_freq) * speed_amp
	position.x += current_speed * delta

func _immitade_wave() -> void:
	position.y = _pos_y + _noise.get_noise_1d(_time) * wave_amp

func _draw() -> void:
	draw_line(
		Vector2.ZERO, 
		Vector2(distance, 0), 
		Color.CADET_BLUE, 
		2)
