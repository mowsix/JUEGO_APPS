extends CharacterBody2D

# ============ CONFIGURACIÓN EXPORTABLE ============
@export_group("Movimiento")
@export var move_speed: float = 60.0
@export var gravity: float = 900.0
@export var patrol_range: float = 900.0

@export_group("Combate")
@export var health: int = 3
@export var max_health: int = 3
@export var damage: int = 1
@export var attack_cooldown_time: float = 1.5   # ← delay entre ataques

@export_group("Targeting")
@export var player_path: NodePath
@export var detection_range: float = 1200.0

@export_group("Respawn")
@export var respawn_time: float = 2.0

@export_group("Recompensas")
@export var score_reward: int = 15

@export_group("Debug")
@export var debug_logs: bool = false

# ============ VARIABLES INTERNAS ============
var origin_x: float
var spawn_position: Vector2
var direction: int = 1
var is_dead: bool = false
var can_attack: bool = true              # ← se pone false al iniciar ataque y vuelve a true tras cooldown
var target: Node2D = null
var printed_target_ok: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Usamos tu HurtArea como MELEE
@onready var melee_area: Area2D = $HurtArea
@onready var melee_shape: CollisionShape2D = $HurtArea/CollisionShape2D

# SFX (opcionales)
@onready var sfx_attack: AudioStreamPlayer2D = $SFX_Attack
@onready var sfx_death:  AudioStreamPlayer2D = $SFX_Death

enum State { IDLE, WALK, ATTACK, HURT, DEAD }
var current_state: State = State.WALK

func _ready():
	add_to_group("enemy")

	origin_x = global_position.x
	spawn_position = global_position
	health = max_health

	if sprite:
		sprite.play("walk")
		sprite.animation_changed.connect(_on_animation_changed)
		sprite.animation_finished.connect(_on_animation_finished)

	# MELEE siempre habilitada (evitar flush errors)
	if melee_area:
		melee_area.monitoring = true
		melee_area.monitorable = true
		melee_area.set_collision_layer_value(4, true)  # EnemyHitbox
		melee_area.set_collision_mask_value(1, true)   # PlayerBody
		melee_area.set_collision_mask_value(2, false)
		melee_area.set_collision_mask_value(3, false)
		melee_area.set_collision_mask_value(4, false)
	if melee_shape:
		melee_shape.set_deferred("disabled", false)

	_force_bind_target_from_path()

func _force_bind_target_from_path():
	if player_path == NodePath():
		if debug_logs: push_warning("[Enemy] player_path vacío. Asigna el Player en el Inspector.")
		return
	var n := get_node_or_null(player_path)
	if n == null or not (n is Node2D):
		push_error("[Enemy] player_path inválido o no es Node2D.")
		return
	target = n
	if debug_logs: print("[Enemy] Target por path OK → ", target.name)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	_update_melee_area_orientation()

	if target == null or not is_instance_valid(target):
		_force_bind_target_from_path()
	else:
		if debug_logs and not printed_target_ok:
			print("[Enemy] Operando con target: ", target.name)
			printed_target_ok = true

	match current_state:
		State.WALK:
			_ai_follow_and_attack()
		State.ATTACK:
			velocity.x = 0.0
		State.HURT, State.DEAD:
			velocity.x = 0.0

	move_and_slide()

	if (target == null or not is_instance_valid(target)) and is_on_wall():
		direction *= -1

func _update_melee_area_orientation() -> void:
	if melee_area == null:
		return
	var off: float = absf(melee_area.position.x)
	melee_area.position.x = -off if direction < 0 else off

# ================== IA / PERSECUCIÓN ==================
func _ai_follow_and_attack() -> void:
	if target and is_instance_valid(target):
		var to_vec := target.global_position - global_position
		var dist: float = to_vec.length()

		var dir_to_target: float = signf(to_vec.x)
		if dir_to_target != 0.0:
			direction = int(dir_to_target)
		if sprite:
			sprite.flip_h = direction < 0

		if dist <= detection_range:
			if _player_inside_melee_area():
				velocity.x = 0.0
				_start_attack()
				return
			velocity.x = direction * move_speed
		else:
			velocity.x = direction * move_speed
	else:
		velocity.x = direction * move_speed
		if absf(global_position.x - origin_x) > patrol_range:
			direction *= -1

	if sprite and current_state != State.ATTACK and current_state != State.HURT:
		_set_state(State.WALK)

func _player_inside_melee_area() -> bool:
	if not melee_area:
		return false
	for b in melee_area.get_overlapping_bodies():
		if b and b.is_in_group("player"):
			var to_vec := (b as Node2D).global_position - global_position
			if signf(to_vec.x) == float(direction): # delante
				return true
	return false

# ================== ATAQUE ==================
func _start_attack() -> void:
	if is_dead or not can_attack:
		return
	if target == null or not is_instance_valid(target):
		return
	# Lock de ataque hasta terminar animación + cooldown
	can_attack = false
	_set_state(State.ATTACK)

func _on_animation_changed() -> void:
	if sprite and _attack_anim_playing():
		if sfx_attack:
			sfx_attack.stop()
			sfx_attack.play()
		# Ventana de golpe durante la animación
		await get_tree().create_timer(0.05).timeout
		if sprite and _attack_anim_playing():
			_apply_melee_hit()
			await get_tree().create_timer(0.05).timeout
			_apply_melee_hit()

func _apply_melee_hit() -> void:
	if is_dead or current_state != State.ATTACK:
		return
	if target == null or not is_instance_valid(target):
		return
	# Debe estar dentro del HurtArea y al frente
	for b in melee_area.get_overlapping_bodies():
		if b and b.is_in_group("player") and b.has_method("take_damage"):
			var to_vec := (b as Node2D).global_position - global_position
			if signf(to_vec.x) == float(direction):
				b.take_damage(damage)
				return  # golpe dado (el cooldown lo maneja animation_finished)

func _on_animation_finished() -> void:
	# Cuando termina la animación de ataque, siempre esperamos el cooldown
	if current_state == State.ATTACK:
		if not is_dead:
			_set_state(State.WALK)
		await get_tree().create_timer(attack_cooldown_time).timeout
		can_attack = true

# Helpers animación
func _attack_anim_playing() -> bool:
	if not sprite: return false
	var a := sprite.animation
	return a == "attack" or a == "Attack"

# ============= DAÑO / MUERTE / RESPAWN =============
func take_damage(dmg: int) -> void:
	if is_dead:
		return
	
	health -= dmg
	_set_state(State.HURT)
	
	# EFECTO VISUAL: Pintar de rojo
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color(1.0, 0.0, 0.0, 1.0)  # Rojo puro
		
		# Crear un tween para volver al color original
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original_modulate, 0.3)
	
	if health <= 0:
		die()
	else:
		# Esperar a que termine la animación de hurt antes de volver a WALK
		if sprite and sprite.sprite_frames.has_animation("hurt"):
			await sprite.animation_finished
		else:
			await get_tree().create_timer(0.25).timeout
		
		if not is_dead:
			_set_state(State.WALK)

func die() -> void:
	Global.add_kill(1)
	is_dead = true
	if sfx_death:
		sfx_death.stop()
		sfx_death.play()
	_set_state(State.DEAD)
	if sprite and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	else:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
		await tween.finished
	Global.add_score(score_reward)
	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _respawn() -> void:
	global_position = spawn_position
	health = max_health
	is_dead = false
	can_attack = true
	direction = 1
	origin_x = spawn_position.x
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.play("walk")
	target = null
	_force_bind_target_from_path()
	printed_target_ok = false
	_set_state(State.WALK)

# ================== FSM helper ==================
func _set_state(new_state: State) -> void:
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
			elif sprite.sprite_frames.has_animation("Attack"):
				sprite.play("Attack")
			elif sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
		State.HURT:
			if sprite.sprite_frames.has_animation("hurt"):
				sprite.play("hurt")
		State.DEAD:
			if sprite.sprite_frames.has_animation("death"):
				sprite.play("death")
