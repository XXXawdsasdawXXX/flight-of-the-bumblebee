class_name BeeStateMachine
extends Node

signal state_changed(previous: State, next: State)

enum State { FLY, ANGRY, TURN }

var current: State = State.FLY


func is_fly() -> bool:
	return current == State.FLY


func is_angry() -> bool:
	return current == State.ANGRY


func is_turn() -> bool:
	return current == State.TURN


func set_state(next: State) -> bool:
	if current == next:
		return false
	var previous := current
	current = next
	state_changed.emit(previous, next)
	return true
