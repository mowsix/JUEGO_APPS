extends CharacterBody2D

signal player_hurt
signal player_attack

@export var move_speed:float = 140.0
@export var jump_velocity:float = -280.0
@export var gravity:float = 900.0
@export var attack_cost:float = 10.0
@export var attack_time:float = 0.15
@export var hurt_time:float = 0.4
@export var hp:int = 3

var attack_cooldown:bool = false

enum State { IDLE, WALK, JUMP, ATTACK, HURT, DEAD }
var state:State = State.IDLE

# <-- aquí uso @onready y la ruta correcta del nodo según tu escena
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

func _ready():
	# chequeos seguros por si cambias nombres
	if has_node("AnimatedSprite2D"):
		sprite.modulate = Color(0.9, 0.9, 1.0, 1.0)
	if has_node("AttackArea/CollisionShape2D"):
		attack_shape.disabled = true

	sprite.play("idle")
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _physics_process(delta):
	if state == State.DEAD:
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return

	if state == State.HURT:
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	var dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = dir * move_speed

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		_set_state(State.JUMP)

	if Input.is_action_just_pressed("attack"):
		_try_attack()

	move_and_slide()

	if dir > 0:
		sprite.flip_h = false
	elif dir < 0:
		sprite.flip_h = true

	if state != State.ATTACK and state != State.HURT and state != State.DEAD:
		if not is_on_floor():
			_set_state(State.JUMP)
		else:
			if abs(velocity.x) > 10:
				_set_state(State.WALK)
			else:
				_set_state(State.IDLE)

func _set_state(new_state:State) -> void:
	if state == new_state:
		return
	state = new_state
	match state:
		State.IDLE:
			sprite.play("idle")
		State.WALK:
			sprite.play("walk")
		State.JUMP:
			sprite.play("jump")
		State.ATTACK:
			sprite.play("attack1")
		State.HURT:
			sprite.play("hurt")
		State.DEAD:
			sprite.play("dead")

func _try_attack() -> void:
	if attack_cooldown or state == State.DEAD or state == State.HURT:
		return

	attack_cooldown = true
	emit_signal("player_attack")
	_set_state(State.ATTACK)
	if attack_shape:
		attack_shape.disabled = false

	await get_tree().create_timer(attack_time).timeout
	if attack_shape:
		attack_shape.disabled = true

	await get_tree().create_timer(0.2).timeout
	attack_cooldown = false

	if state == State.ATTACK:
		if is_on_floor():
			if abs(velocity.x) > 10:
				_set_state(State.WALK)
			else:
				_set_state(State.IDLE)
		else:
			_set_state(State.JUMP)

func _on_animation_finished(anim_name:String) -> void:
	if anim_name == "attack1":
		if state == State.ATTACK:
			if is_on_floor():
				if abs(velocity.x) > 10:
					_set_state(State.WALK)
				else:
					_set_state(State.IDLE)
			else:
				_set_state(State.JUMP)
	elif anim_name == "hurt":
		if state == State.HURT:
			if hp <= 0:
				_set_state(State.DEAD)
			else:
				if is_on_floor():
					if abs(velocity.x) > 10:
						_set_state(State.WALK)
					else:
						_set_state(State.IDLE)
				else:
					_set_state(State.JUMP)

func take_damage(amount:int = 1) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	emit_signal("player_hurt")
	_set_state(State.HURT)
	if attack_shape:
		attack_shape.disabled = true
	velocity.y = -80
	await get_tree().create_timer(hurt_time).timeout
	if hp <= 0:
		_set_state(State.DEAD)
