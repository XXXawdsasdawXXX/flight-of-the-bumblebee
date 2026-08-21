class_name FishAnimator
extends Node

@export var spine: SpineSprite
@export var swim_clip: String = "Swim"
@export var agr_clip: String = "Agr"
@export var start_fly_clip: String = "Agr_Start_Fly"
@export var fly_up_clip: String = "Agr_Fly_up"
@export var reverse_clip: String = "Agr_Revere"
@export var fly_down_clip: String = "Agr_Fly_Down"
@export var eat_clip: String = "Agr_Fly_Down_Eat"
@export var fly_down_close_clip: String = "Agr_Fly_Down_Close"
@export var land_clip: String = "Agr_Fly_Down_Close_Landing"

var _current_clip: String
var _current_loop: bool


func play_eat() -> float:
	return play(eat_clip, false)


func play_fly_down_close() -> void:
	play(fly_down_close_clip, true)


func play_land() -> float:
	return play(land_clip, false)


func play_reverse() -> float:
	return play(reverse_clip, false)
	
	
func play_fly_down() -> void:
	play(fly_down_clip, true)


func play_fly_up() -> void:
	play(fly_up_clip, true)


func play_start_fly() -> float:
	return play(start_fly_clip, false)


func play_swim() -> void:
	play(swim_clip, true)


func play_agr() -> float:
	return play(agr_clip, false)


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
