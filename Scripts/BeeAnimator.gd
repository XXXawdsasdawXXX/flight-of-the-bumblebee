class_name BeeAnimator
extends Node

signal clip_ended(clip_name: String)

@export var spine: SpineSprite
@export var angry_clip: String = "Fly_Angry"
@export var angry_exit_clip: String = "Fly_Angry"
@export var take_bird_clip: String = "Take_Bird"
@export var bird_idle_clip: String = "Fly_Bird"
@export var lost_bird_clip: String = "Lost_Bird"
@export var turn_clip: String = "Fly_Angry_Reverse"
@export var fly_clip: String = "Fly"
@export var min_clip_duration: float = 0.4
@export var turn_duration: float = 0.7

var _current_clip: String 
var _current_loop: bool 


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
	var resume_clip := _current_clip
	var resume_loop := _current_loop
	
	if resume_clip.is_empty() or resume_clip == turn_clip:
		resume_clip = angry_clip
		resume_loop = true
	
	var entry : Variant = _set_clip(turn_clip, false)
	var duration := _clip_duration(entry)
	
	_queue_resume(resume_clip, resume_loop)
	return duration



func _queue_resume(clip_name: String, loop: bool) -> void:
	var anim_state: Variant = spine.get_animation_state()
	if anim_state == null:
		return
	anim_state.add_animation(clip_name, 0.0, loop, 0)


func play(clip_name: String, loop: bool, reverse: bool = false) -> float:
	var entry : Variant = _set_clip(clip_name, loop, reverse)
	if entry == null:
		return min_clip_duration
	var duration := _clip_duration(entry)
	return duration


func _set_clip(clip_name: String, loop: bool, reverse: bool = false) -> Variant:
	_current_clip = clip_name
	_current_loop = loop
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
	entry.set_reverse(reverse)
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
