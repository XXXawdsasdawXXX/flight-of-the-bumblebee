extends CharacterBody2D

@export var view: SpineSprite
@export var max_speed: float = 1 
@export var acceleration: float = 1 
@export var friction: float = 1 
@export var jump_velocity: float = -10 

var alive: bool = true


func _physics_process(delta: float) -> void:
	_jump(delta)
	_move(delta)
	move_and_slide()


func die() -> void:
	alive = false
	hide()
	set_physics_process(false)


func _jump(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("move_up") and is_on_floor():
		velocity.y = jump_velocity
	
	
func _move(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * max_speed, acceleration * delta)
		view.scale.x = abs(view.scale.x) * dir
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
