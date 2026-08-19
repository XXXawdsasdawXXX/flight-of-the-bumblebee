extends Node2D

@export var spine: SpineSprite
@export var states: BeeStateMachine
@export var mover: BeeMover
@export var bone_names: PackedStringArray

## Разделитель между лапками внутри `bone_names`.
## Пример: ["L21","L22","L23","-","L30","L31"] — две лапки.
@export var group_separator: String = "-"
## Насколько сильно скорость превращается в целевой угол.
@export var drag: float = 0.002
## Максимальный добавляемый угол (в радианах).
@export var max_angle: float = 0.25
## Насколько быстро лапки подстраиваются к целевому углу (чем больше — тем быстрее).
@export var follow: float = 10.0

## Множитель угла для корневой кости лапки (первая кость в группе).
@export var root_leg_multiplier: float = 1.1

## Множитель угла для кончика лапки (последняя кость в группе).
@export var tip_leg_multiplier: float = 0.7

## Форма интерполяции корень->кончик.
## 1.0 = линейно. >1 сильнее прижимает влияние к корню, <1 делает мягче по длине.
@export var leg_multiplier_power: float = 1.0
## Дополнительное сглаживание "ломаной" между соседними костями в лапке.
## 0.0 = без сглаживания, 1.0 = максимально мягкая дуга.
@export var chain_smooth: float = 0.45

## За сколько секунд плавно вернуть лапки к нейтральному положению,
## когда мы выходим из состояния FLY (и Spine начинает другую анимацию).
@export var return_seconds: float = 0.25
var _prev_global: Vector2
var _angles: PackedFloat32Array = PackedFloat32Array()
var _bones: Array = []
var _applied_angles: PackedFloat32Array = PackedFloat32Array()
var _group_id: PackedInt32Array = PackedInt32Array()
var _pos_in_group: PackedInt32Array = PackedInt32Array()
var _group_sizes: Array = []
var _prev_is_fly: bool = false
var _return_time_left: float = 0.0
var _apply_alpha: float = 1.0


func _ready() -> void:
	_prev_global = global_position
	if Engine.is_editor_hint():
		return
	call_deferred("_bind_spine")


func _bind_spine() -> void:
	if spine == null and get_parent() is SpineSprite:
		spine = get_parent()
	if spine == null:
		push_warning("InsectLeg: SpineSprite не назначен")
		return
	_resolve_bones()
	if _bones.is_empty():
		return
	# Применяем после пересчёта скелета, чтобы Spine не перезатирал наши правки.
	# world_transforms_changed эмитится после skeleton update/apply и update_world_transform.
	if not spine.world_transforms_changed.is_connected(_apply_to_spine):
		spine.world_transforms_changed.connect(_apply_to_spine)


func _resolve_bones() -> void:
	_bones.clear()
	var skeleton: Variant = spine.get_skeleton()
	if skeleton == null:
		push_warning("InsectLeg: skeleton пустой")
		return

	var available: PackedStringArray = PackedStringArray()
	for bone in skeleton.get_bones():
		var n := _bone_name(bone)
		if not n.is_empty():
			available.append(n)

	var names := bone_names.duplicate()
	if names.is_empty():
		for n in available:
			if n.begins_with("L") and n.substr(1).is_valid_int():
				names.append(n)

	_group_id = PackedInt32Array()
	_pos_in_group = PackedInt32Array()
	_group_sizes = [0]
	var group_index := 0
	var pos_in_group := 0

	for token in names:
		if token == group_separator:
			_group_sizes[group_index] = pos_in_group
			group_index += 1
			pos_in_group = 0
			_group_sizes.append(0)
			continue

		var bone: Variant = skeleton.find_bone(token)
		if bone == null:
			continue

		if bone.has_method("is_active") and bone.has_method("set_active"):
			if not bone.is_active():
				bone.set_active(true)

		_bones.append(bone)
		_group_id.push_back(group_index)
		_pos_in_group.push_back(pos_in_group)
		pos_in_group += 1

	# finalize last group size
	_group_sizes[group_index] = pos_in_group

	_angles.resize(_bones.size())
	_applied_angles.resize(_bones.size())
	for i in range(_applied_angles.size()):
		_applied_angles[i] = 0.0
	if _bones.is_empty():
		push_warning("InsectLeg: не нашёл лапки. Кости: " + ", ".join(available))
	else:
		pass


func _bone_name(bone: Variant) -> String:
	if bone == null or not bone.has_method("get_data"):
		return ""
	var data: Variant = bone.get_data()
	if data == null or not data.has_method("get_name"):
		return ""
	return String(data.get_name())


func _process(delta: float) -> void:
	var fly_only := states != null
	var is_fly := fly_only and states.is_fly()

	# На первом кадре просто запоминаем текущее состояние.
	if _prev_is_fly == false and _return_time_left == 0.0 and _apply_alpha == 1.0:
		_prev_is_fly = is_fly

	if is_fly:
		_apply_alpha = 1.0
		_return_time_left = 0.0
	else:
		# Начинаем мягкий возврат при выходе из FLY.
		if _prev_is_fly:
			_return_time_left = maxf(return_seconds, 0.0001)

		if _return_time_left > 0.0:
			_apply_alpha = _return_time_left / maxf(return_seconds, 0.0001)
			_return_time_left -= delta
			if _return_time_left < 0.0:
				_return_time_left = 0.0
		else:
			_apply_alpha = 0.0

		# Плавно ведём целевой угол к 0 (чтобы при альфе > 0 откат был гладким).
		var k_off := 1.0 - exp(-follow * delta)
		for i in _angles.size():
			_angles[i] = lerp_angle(_angles[i], 0.0, k_off)
		_prev_is_fly = is_fly
		return

	var speed := 0.0
	var dir_sign := 1.0

	# В спокойном FLY берём скорость напрямую из BeeMover.
	if mover != null:
		speed = mover.current_speed
		dir_sign = 1.0 if mover.going_forward else -1.0
		# Учитываем зеркалирование тела (если scale.x отрицательный, локальные оси часто меняют знак).
		if mover.body != null:
			var sc := mover.body.scale.x
			var sc_sign := -1.0 if sc >= 0.0 else 1.0
			dir_sign *= sc_sign
	else:
		# Fallback: скорость по перемещению узла.
		var velocity: Vector2 = (global_position - _prev_global) / maxf(delta, 0.0001)
		_prev_global = global_position
		var local_vel: Vector2 = -global_transform.affine_inverse().basis_xform(velocity)
		speed = velocity.length()
		dir_sign = signf(local_vel.x)
		if is_zero_approx(dir_sign):
			dir_sign = 1.0

	var target: float = clampf(speed * drag, 0.0, max_angle) * dir_sign
	var final_target := target
	var k := 1.0 - exp(-follow * delta)
	var count := _angles.size()
	for i in count:
		# Множитель считается отдельно по каждой "лапке" (группа до разделителя).
		var gid :=  _group_id[i] if (i < _group_id.size()) else 0
		var gsize := int(_group_sizes[gid]) if (gid >= 0 and gid < _group_sizes.size()) else count
		var p :=  _pos_in_group[i] if (i < _pos_in_group.size()) else 0
		var t := 0.0
		if gsize > 1:
			t = float(p) / float(gsize - 1) # 0 = корень, 1 = кончик
		var tp := t
		if leg_multiplier_power != 1.0:
			tp = pow(tp, leg_multiplier_power)
		var mul := lerpf(root_leg_multiplier, tip_leg_multiplier, tp)
		_angles[i] = lerp_angle(_angles[i], final_target * mul, k)

	# Убираем "ломаную": сглаживаем разницу между соседними костями внутри каждой лапки.
	# Делаем лёгкий проход от корня к кончику и обратно.
	if count > 2 and chain_smooth > 0.0:
		var s := clampf(chain_smooth, 0.0, 1.0)
		var prev_gid := -1
		# Forward pass
		for i in count:
			var gid := _group_id[i] if i < _group_id.size() else 0
			if gid != prev_gid:
				prev_gid = gid
				continue
			_angles[i] = lerp_angle(_angles[i], _angles[i - 1], s * 0.35)
		# Backward pass
		prev_gid = -1
		for i in range(count - 1, -1, -1):
			var gid := _group_id[i] if i < _group_id.size() else 0
			if gid != prev_gid:
				prev_gid = gid
				continue
			_angles[i] = lerp_angle(_angles[i], _angles[i + 1], s * 0.2) if i + 1 < count and (_group_id[i + 1] if i + 1 < _group_id.size() else gid) == gid else _angles[i]

	_prev_is_fly = is_fly

	# (debug removed)


func _apply_to_spine(_sprite: Variant = null) -> void:
	for i in _bones.size():
		var bone: Variant = _bones[i]
		if bone == null:
			continue

		# Важно: set_rotation/set_applied_rotation может не помечать skeleton как "modified",
		# поэтому меши не пересчитаются и визуально ничего не будет видно.
		# set_transform/rotate_world чаще работает, потому что SpineBone при этом помечает modified_bones.
		var effective_rad := _angles[i] * _apply_alpha
		var applied_rad := (_applied_angles[i] if i < _applied_angles.size() else 0.0)
		var delta_rad := effective_rad - applied_rad

		if bone.has_method("get_transform") and bone.has_method("set_transform"):
			if absf(delta_rad) < 0.00001:
				continue
			var xform: Transform2D = bone.get_transform()
			bone.set_transform(xform.rotated(delta_rad))
			if i < _applied_angles.size():
				_applied_angles[i] = effective_rad
		elif bone.has_method("set_rotation") and bone.has_method("get_rotation"):
			var delta_deg := rad_to_deg(delta_rad)
			if absf(delta_deg) < 0.00001:
				continue
			bone.set_rotation(bone.get_rotation() + delta_deg)
			if i < _applied_angles.size():
				_applied_angles[i] = effective_rad
		elif bone.has_method("set_applied_rotation") and bone.has_method("get_applied_rotation"):
			var delta_deg := rad_to_deg(delta_rad)
			if absf(delta_deg) < 0.00001:
				continue
			bone.set_applied_rotation(bone.get_applied_rotation() + delta_deg)
			if i < _applied_angles.size():
				_applied_angles[i] = effective_rad
