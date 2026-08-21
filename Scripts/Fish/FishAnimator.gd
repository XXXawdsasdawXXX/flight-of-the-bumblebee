class_name FishAnimator
extends Node

@export var spine: SpineSprite
@export var swim_clip: String = "Swim"

var _current_clip: String
var _current_loop: bool


func play_swim() -> void:
	play(swim_clip, true)


func play(clip_name: String, loop: bool, reverse: bool = false) -> float:
	var entry : Variant = _set_clip(clip_name, loop, reverse)
	if entry == null:
		return 0
	var duration := _clip_duration(entry)
	return duration


func _set_clip(clip_name: String, loop: bool, reverse: bool = false) -> Variant:
	_current_clip = clip_name
	_current_loop = loop
	if spine == null:
		push_warning("FishAnimator: SpineSprite не назначен")
		return null
	var anim_state: Variant = spine.get_animation_state()
	if anim_state == null:
		push_warning("FishAnimator: animation state пустой")
		return null
	var entry: Variant = anim_state.set_animation(clip_name, loop, 0)
	if entry == null:
		push_warning("FishAnimator: нет клипа " + clip_name)
		return null
	entry.set_reverse(reverse)
	entry.set_mix_duration(0.25)
	return entry


func _clip_duration(entry: Variant) -> float:
	if entry != null and entry.has_method("get_animation_end"):
		return maxf(0, entry.get_animation_end())
	return 0
