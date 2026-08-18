class_name BeeWave
extends Node

@export var target: Node2D

var _time: float

func tick(delta: float, amp: float, freq: float) -> void:
	_time += delta
	target.position.y = sin(_time * freq) * amp
