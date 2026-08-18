class_name BeeWave
extends Node

@export var target: Node2D
@export var amp: float = 10.0
@export var freq: float = 3.0

var _time: float


func tick_fly(delta: float) -> void:
	_tick(delta, amp, freq)


func tick_custom(delta: float, custom_amp: float, custom_freq: float) -> void:
	_tick(delta, custom_amp, custom_freq)


func _tick(delta: float, wave_amp: float, wave_freq: float) -> void:
	_time += delta
	target.position.y = sin(_time * wave_freq) * wave_amp
