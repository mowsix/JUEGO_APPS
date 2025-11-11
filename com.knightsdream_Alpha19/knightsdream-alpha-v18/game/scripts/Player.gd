extends CharacterBody2D

@export_group("Movimiento")
@export var move_speed: float = 120.0
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

# --- NUEVOS AJUSTES ---
@export var attack_forward_margin: float = 12.0
@export var attack_vertical_offset: float = 0.0
@export var visual_manual_offset: Vector2 = Vector2(-80, -50)

# -----------------------

var hp: int = 5
var attack_cooldown: bool = false
var is_invincible: bool = false
var is_dead: bool = false
var is_attacking: bool = false

signal player_hurt
signal player_attack
signal player_died
signal hp_changed(new_hp, max_hp)

@onready var facing: Node2D = $Facing
@onready var sprite: AnimatedSprite2D = $Facing/AnimatedSprite2D
@onready var attack_area: Area2D = $Facing/AttackArea
@onready var attack_shape: CollisionShape2D = $Facing/AttackArea/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var sfx_attack: AudioStreamPlayer2D = $SFX_Attack
@onready var sfx_hurt: AudioStreamPlayer2D = $SFX_Hurt
@onready var sfx_death: AudioStreamPlayer2D = $SFX_Death

enum State { IDLE, WALK, JUMP, ATTACK, HURT, DEAD }
var state: State = State.IDLE

func _ready() -> void:
	add_to_group("player")
	hp = max_hp

	# --- 🔧 CENTRAMOS TODO ---
	body_shape.position = Vector2.ZERO
	facing.position = Vector2.ZERO
	sprite.centered = true
	sprite.offset = Vector2.ZERO
	sprite.position = Vector2.ZERO
	attack_shape.position = Vector2.ZERO
	attack_area.position = Vector2.ZERO
	# -------------------------

	sprite.animation_finished.connect(_on_animation_finished)
	sprite.animation_changed.connect(_on_animation_changed)

	if attack_shape:
		attack_shape.disabled = true
	if attack_area and not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	emit_signal("hp_changed", hp, max_hp)

func _physics_process(delta: float) -> void:
	if is_dead:
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return

	if state == State.HURT or state == State.ATTACK:
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	var dir: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = dir * move_speed

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		_set_state(State.JUMP)

	if Input.is_action_just_pressed("attack"):
		_try_attack()

	# Flip SOLO del sprite
	if dir > 0.1:
		sprite.flip_h = false
	elif dir < -0.1:
		sprite.flip_h = true

	# Centra sprite dentro del hitbox
	_apply_visual_center()
	# Mueve el área de ataque justo delante
	_update_attack_area_from_hitbox()

	move_and_slide()

	if state != State.ATTACK and state != State.HURT and state != State.DEAD:
		if not is_on_floor():
			_set_state(State.JUMP)
		else:
			if abs(velocity.x) > 10.0:
				_set_state(State.WALK)
			else:
				_set_state(State.IDLE)

# 🔧 Alinea sprite sobre el hitbox
func _apply_visual_center() -> void:
	sprite.position = visual_manual_offset

# 🔧 Coloca el área de ataque al borde del hitbox
func _update_attack_area_from_hitbox() -> void:
	if body_shape == null or body_shape.shape == null:
		return

	var half := Vector2.ZERO
	var sh := body_shape.shape
	if sh is RectangleShape2D:
		half = sh.size * 0.5
	elif sh is CapsuleShape2D:
		half = Vector2(sh.radius, sh.height * 0.5)
	elif sh is CircleShape2D:
		half = Vector2(sh.radius, sh.radius)

	var side := -1.0 if sprite.flip_h else 1.0
	var x := side * (half.x + attack_forward_margin)
	var y := attack_vertical_offset
	attack_area.position = Vector2(x, y)

func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state

	if not sprite or not sprite.sprite_frames:
		return

	match state:
		State.IDLE:
			if sprite.sprite_frames.has_animation("idle"): sprite.play("idle")
		State.WALK:
			if sprite.sprite_frames.has_animation("walk"): sprite.play("walk")
		State.JUMP:
			if sprite.sprite_frames.has_animation("jump"): sprite.play("jump")
		State.ATTACK:
			if sprite.sprite_frames.has_animation("attack"): sprite.play("attack")
			else: sprite.play("idle")
		State.HURT:
			if sprite.sprite_frames.has_animation("hurt"): sprite.play("hurt")
		State.DEAD:
			if sprite.sprite_frames.has_animation("dead"): sprite.play("dead")

func _try_attack() -> void:
	if attack_cooldown or state == State.DEAD or state == State.HURT or is_attacking:
		return
	if not Global.spend_mana(attack_cost):
		return

	is_attacking = true
	attack_cooldown = true

	if sfx_attack:
		sfx_attack.stop()
		sfx_attack.play()

	emit_signal("player_attack")
	_set_state(State.ATTACK)

	await get_tree().create_timer(0.1).timeout
	attack_cooldown = false

func _on_animation_changed() -> void:
	if sprite.animation == "attack":
		await get_tree().create_timer(0.05).timeout
		if sprite.animation == "attack":
			attack_shape.disabled = false
	else:
		attack_shape.disabled = true

func _on_animation_finished() -> void:
	if sprite.animation == "attack":
		attack_shape.disabled = true
		is_attacking = false
		if is_on_floor():
			_set_state(State.IDLE)
		else:
			_set_state(State.JUMP)

func take_damage(amount: int = 1) -> void:
	if is_invincible or is_dead:
		return

	hp -= amount
	emit_signal("player_hurt")
	emit_signal("hp_changed", hp, max_hp)

	if sfx_hurt:
		sfx_hurt.stop()
		sfx_hurt.play()

	Global.mana = max(0.0, Global.mana - 5.0)

	is_attacking = false
	attack_cooldown = false

	_set_state(State.HURT)

	is_invincible = true
	_flash_sprite()

	if hp <= 0:
		die()
	else:
		await get_tree().create_timer(hurt_time).timeout
		is_invincible = false
		if state == State.HURT:
			_set_state(State.IDLE)

func die() -> void:
	is_dead = true

	if sfx_death:
		sfx_death.stop()
		sfx_death.play()

	_set_state(State.DEAD)
	emit_signal("player_died")

	if sprite and sprite.sprite_frames.has_animation("dead"):
		await sprite.animation_finished

	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func _flash_sprite() -> void:
	for i in range(6):
		sprite.modulate.a = 0.3
		await get_tree().create_timer(0.1).timeout
		sprite.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

func _on_attack_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
		Global.add_score(5)
