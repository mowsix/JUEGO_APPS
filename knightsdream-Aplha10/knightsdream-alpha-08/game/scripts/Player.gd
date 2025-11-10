extends CharacterBody2D

# ============ CONFIGURACIÓN EXPORTABLE ============
@export_group("Movimiento")
@export var move_speed: float = 140.0
@export var jump_velocity: float = -280.0
@export var gravity: float = 900.0

@export_group("Combate")
@export var max_hp: int = 5
@export var attack_damage: int = 1
@export var attack_cost: float = 10.0
@export var attack_time: float = 0.15
@export var hurt_time: float = 0.4

@export_group("Invencibilidad")
@export var invincibility_time: float = 1.0

# ============ VARIABLES INTERNAS ============
var hp: int = 5
var attack_cooldown: bool = false
var is_invincible: bool = false
var is_dead: bool = false

# ============ SEÑALES ============
signal player_hurt
signal player_attack
signal player_died
signal hp_changed(new_hp, max_hp)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

# ============ ESTADOS ============
enum State { IDLE, WALK, JUMP, ATTACK, HURT, DEAD }
var state: State = State.IDLE

func _ready():
	hp = max_hp
	if sprite:
		sprite.modulate = Color(0.9, 0.9, 1.0, 1.0)
	if attack_shape:
		attack_shape.disabled = true
	
	emit_signal("hp_changed", hp, max_hp)

func _physics_process(delta):
	if is_dead:
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return
	
	if state == State.HURT:
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return
	
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Movimiento horizontal
	var dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = dir * move_speed
	
	# Salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		_set_state(State.JUMP)
	
	# Ataque
	if Input.is_action_just_pressed("attack"):
		_try_attack()
	
	move_and_slide()
	
	# Voltear sprite
	if sprite:
		if dir > 0:
			sprite.flip_h = false
		elif dir < 0:
			sprite.flip_h = true
	
	# Actualizar estado visual
	if state != State.ATTACK and state != State.HURT and state != State.DEAD:
		if not is_on_floor():
			_set_state(State.JUMP)
		else:
			if abs(velocity.x) > 10:
				_set_state(State.WALK)
			else:
				_set_state(State.IDLE)

func _set_state(new_state: State):
	if state == new_state:
		return
	
	state = new_state
	
	if not sprite or not sprite.sprite_frames:
		return
	
	match state:
		State.IDLE:
			if sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
		State.WALK:
			if sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")
		State.JUMP:
			if sprite.sprite_frames.has_animation("jump"):
				sprite.play("jump")
		State.ATTACK:
			if sprite.sprite_frames.has_animation("attack"):
				sprite.play("attack")
		State.HURT:
			if sprite.sprite_frames.has_animation("hurt"):
				sprite.play("hurt")
		State.DEAD:
			if sprite.sprite_frames.has_animation("dead"):
				sprite.play("dead")

func _try_attack():
	if attack_cooldown or state == State.DEAD or state == State.HURT:
		return
	
	if not Global.spend_mana(attack_cost):
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

func take_damage(amount: int = 1):
	if is_invincible or is_dead:
		return
	
	hp -= amount
	emit_signal("player_hurt")
	emit_signal("hp_changed", hp, max_hp)
	
	Global.mana = max(0.0, Global.mana - 5.0)
	
	_set_state(State.HURT)
	
	# Efecto visual de daño
	is_invincible = true
	_flash_sprite()
	
	if hp <= 0:
		die()
	else:
		await get_tree().create_timer(hurt_time).timeout
		is_invincible = false
		if state == State.HURT:
			_set_state(State.IDLE)

func die():
	is_dead = true
	_set_state(State.DEAD)
	emit_signal("player_died")
	
	# Esperar animación de muerte
	if sprite and sprite.sprite_frames.has_animation("dead"):
		await sprite.animation_finished
	
	# Aquí puedes mostrar game over o reiniciar nivel
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func _flash_sprite():
	# Efecto de parpadeo cuando recibe daño
	for i in range(6):
		if sprite:
			sprite.modulate.a = 0.3
		await get_tree().create_timer(0.1).timeout
		if sprite:
			sprite.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

func _on_attack_area_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
		Global.add_score(5)
