extends CharacterBody2D

# ============ CONFIGURACIÓN EXPORTABLE ============
@export_group("Movimiento")
@export var move_speed: float = 60.0
@export var gravity: float = 900.0
@export var patrol_range: float = 150.0

@export_group("Combate")
@export var health: int = 3
@export var max_health: int = 3
@export var damage: int = 1
@export var attack_cooldown_time: float = 1.0

@export_group("Recompensas")
@export var score_reward: int = 15

# ============ VARIABLES INTERNAS ============
var origin_x: float
var direction: int = 1
var is_dead: bool = false
var can_attack: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_area: Area2D = $HurtArea

# ============ ESTADOS ============
enum State { IDLE, WALK, ATTACK, HURT, DEAD }
var current_state: State = State.WALK

func _ready():
	origin_x = global_position.x
	health = max_health
	if sprite:
		sprite.play("walk")

func _physics_process(delta):
	if is_dead:
		return
	
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Comportamiento según estado
	match current_state:
		State.WALK:
			_handle_walk()
		State.HURT:
			velocity.x = 0
		State.DEAD:
			velocity.x = 0
	
	move_and_slide()

func _handle_walk():
	# Movimiento horizontal
	velocity.x = direction * move_speed
	
	# Voltear sprite según dirección
	if sprite:
		sprite.flip_h = direction < 0
	
	# Cambiar dirección al alcanzar límite de patrulla
	if abs(global_position.x - origin_x) > patrol_range:
		direction *= -1

func take_damage(dmg: int):
	if is_dead:
		return
	
	health -= dmg
	_set_state(State.HURT)
	
	# Efecto visual de daño
	if sprite:
		sprite.modulate = Color(1.5, 0.5, 0.5)  # Flash rojo
		await get_tree().create_timer(0.15).timeout
		sprite.modulate = Color(1, 1, 1)  # Volver a normal
	
	if health <= 0:
		die()
	else:
		await get_tree().create_timer(0.3).timeout
		if not is_dead:
			_set_state(State.WALK)

func die():
	is_dead = true
	_set_state(State.DEAD)
	
	# Desactivar área de daño
	if hurt_area:
		hurt_area.set_deferred("monitoring", false)
	
	# Animación de muerte
	if sprite and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	else:
		# Si no hay animación de muerte, desvanecer
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		await tween.finished
	
	Global.add_score(score_reward)
	queue_free()

func _set_state(new_state: State):
	if current_state == new_state:
		return
	
	current_state = new_state
	
	if not sprite or not sprite.sprite_frames:
		return
	
	match current_state:
		State.IDLE:
			if sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
		State.WALK:
			if sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")
		State.ATTACK:
			if sprite.sprite_frames.has_animation("attack"):
				sprite.play("attack")
		State.HURT:
			if sprite.sprite_frames.has_animation("hurt"):
				sprite.play("hurt")
		State.DEAD:
			if sprite.sprite_frames.has_animation("death"):
				sprite.play("death")

func _on_hurt_area_body_entered(body):
	if is_dead or not can_attack:
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		can_attack = false
		await get_tree().create_timer(attack_cooldown_time).timeout
		can_attack = true
