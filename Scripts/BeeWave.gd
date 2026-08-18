class_name BeeWave
extends Node

@export var target: Node2D
@export var amp: float = 10.0
@export var freq: float = 3.0

var _blend_speed: float = 0.5
var _amp: float
var _freq: float
var _phase: float


func _ready() -> void:
	_amp = amp
	_freq = freq


func tick(delta: float, target_amp: float, target_freq: float) -> void:
	var progress := 1 - exp(-delta * _blend_speed)
	_amp = lerp(_amp, target_amp, progress) 
	_freq = lerp(_freq, target_freq, progress)
	_phase += _freq * delta
	target.position.y = sin(_phase) * _amp
