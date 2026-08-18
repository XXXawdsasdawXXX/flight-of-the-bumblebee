class_name BeeAnimator
extends Node

signal clip_ended(clip_name: String)

@export var spine: SpineSprite
@export var angry_clip: String = "Fly_Angry"
@export var angry_exit_clip: String = "Fly_Angry"
@export var take_bird_clip: String = "take_bird"
@export var bird_idle_clip: String = "Fly_Bird"
@export var lost_bird_clip: String = "lost_bird"
@export var turn_clip: String = "Fly_Angry_Reverse"
@export var fly_clip: String = "Fly"
@export var min_clip_duration: float = 0.4
@export var turn_duration: float = 0.7


func _ready() -> void:
	if Engine.is_editor_hint() or spine == null:
		return
	spine.preview_animation = "-- Empty --"
	if not spine.animation_ended.is_connected(_on_animation_ended):
		spine.animation_ended.connect(_on_animation_ended)


func play_fly() -> void:
	play(fly_clip, true)


func play_angry() -> void:
	play(angry_clip, true)


func play_angry_exit() -> float:
	return play(angry_exit_clip, false, true)


func play_take_bird() -> float:
	return play(take_bird_clip, false)


func play_bird_idle() -> void:
	play(bird_idle_clip, true)


func play_lost_bird() -> float:
	return play(lost_bird_clip, false)


func play_turn() -> float:
	return maxf(play(turn_clip, false), turn_duration)


func play(clip_name: String, loop: bool, reverse: bool = false) -> float:
	var entry : Variant = _set_clip(clip_name, loop)
	if entry == null:
		return min_clip_duration
	entry.set_mix_duration(0.0)
	var duration := _clip_duration(entry)
	if reverse:
		entry.set_reverse(true)
	print("play " + clip_name)
	return duration


func _set_clip(clip_name: String, loop: bool) -> Variant:
	if spine == null:
		push_warning("BeeAnimator: SpineSprite не назначен")
		return null
	var anim_state: Variant = spine.get_animation_state()
	if anim_state == null:
		push_warning("BeeAnimator: animation state пустой")
		return null
	var entry: Variant = anim_state.set_animation(clip_name, loop, 0)
	if entry == null:
		push_warning("BeeAnimator: нет клипа " + clip_name)
		return null
	return entry


func _clip_duration(entry: Variant) -> float:
	if entry != null and entry.has_method("get_animation_end"):
		return maxf(entry.get_animation_end(), min_clip_duration)
	return min_clip_duration


func _on_animation_ended(_sprite: Variant, _state: Variant, track_entry: Variant) -> void:
	if track_entry == null or not track_entry.has_method("get_animation"):
		return
	var animation: Variant = track_entry.get_animation()
	if animation == null or not animation.has_method("get_name"):
		return
	clip_ended.emit(String(animation.get_name()))
