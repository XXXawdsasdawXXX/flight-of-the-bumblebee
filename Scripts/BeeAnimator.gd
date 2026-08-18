class_name BeeAnimator
extends Node

signal clip_ended(clip_name: String)

@export var spine: SpineSprite
@export var scare_clip: String = "Fly_Angry"
@export var turn_clip: String = "Fly_Angry_Reverse"
@export var fly_clips: PackedStringArray = [
	"Fly",
	"Fly_1",
	"Fly_2",
	"Fly_3",
	"Wings_Back",
]
@export var min_clip_duration: float = 0.4


func _ready() -> void:
	if Engine.is_editor_hint() or spine == null:
		return
	spine.preview_animation = "-- Empty --"
	if not spine.animation_ended.is_connected(_on_animation_ended):
		spine.animation_ended.connect(_on_animation_ended)


func play_fly() -> void:
	play(_random_fly_clip(), true)


func play_chase() -> void:
	play(scare_clip, true)


func play_turn() -> float:
	return play(turn_clip, false)


func play(clip_name: String, loop: bool) -> float:
	if spine == null:
		push_warning("BeeAnimator: SpineSprite не назначен")
		return min_clip_duration
	var anim_state: Variant = spine.get_animation_state()
	if anim_state == null:
		push_warning("BeeAnimator: animation state пустой")
		return min_clip_duration
	var entry: Variant = anim_state.set_animation(clip_name, loop, 0)
	if entry == null:
		push_warning("BeeAnimator: нет клипа " + clip_name)
		return min_clip_duration
	entry.set_mix_duration(0.0)
	if entry.has_method("get_animation_end"):
		return maxf(entry.get_animation_end(), min_clip_duration)
	return min_clip_duration


func _random_fly_clip() -> String:
	if fly_clips.is_empty():
		return "Fly"
	return fly_clips[randi() % fly_clips.size()]


func _on_animation_ended(_sprite: Variant, _state: Variant, track_entry: Variant) -> void:
	if track_entry == null or not track_entry.has_method("get_animation"):
		return
	var animation: Variant = track_entry.get_animation()
	if animation == null or not animation.has_method("get_name"):
		return
	clip_ended.emit(String(animation.get_name()))
