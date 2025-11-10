extends CharacterBody2D

signal player_hurt
signal player_attack

@export var move_speed:float = 140.0
@export var jump_velocity:float = -280.0
@export var gravity:float = 900.0
@export var attack_cost:float = 10.0
@export var attack_time:float = 0.15
@export var attack_cooldown_time:float = 0.25   # <-- cooldown bajo y configurable (segundos)
@export var hurt_time:float = 0.4
@export var hp:int = 3

var attack_cooldown:bool = false

enum State { IDLE, WALK, JUMP, ATTACK, HURT, DEAD }
var state:State = State.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

func _ready():
	# chequeos seguros por si cambias nombres
	if has_node("AnimatedSprite2D"):
		sprite.modulate = Color(0.9, 0.9, 1.0, 1.0)
	if has_node("AttackArea/CollisionShape2D") and attack_shape:
		# set_deferred por seguridad (aunque en _ready no suele haber problema)
		attack_shape.set_deferred("disabled", true)

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
	# No usa mana; sólo cooldown
	if attack_cooldown or state == State.DEAD or state == State.HURT:
		return

	attack_cooldown = true
	emit_signal("player_attack")
	_set_state(State.ATTACK)
	if attack_shape:
		# activar el hitbox de forma diferida para evitar modificaciones durante queries físicas
		attack_shape.set_deferred("disabled", false)

	# duración del hitbox activa (attack_time)
	await get_tree().create_timer(attack_time).timeout
	if attack_shape:
		# desactivar diferido
		attack_shape.set_deferred("disabled", true)

	# cooldown configurable entre ataques
	await get_tree().create_timer(attack_cooldown_time).timeout
	attack_cooldown = false

	# volver a estado de movimiento si la animación ya terminó
	if state == State.ATTACK:
		if is_on_floor():
			if abs(velocity.x) > 10:
				_set_state(State.WALK)
			else:
				_set_state(State.IDLE)
		else:
			_set_state(State.JUMP)

func _on_animation_finished() -> void:
	var anim_name = sprite.animation
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
	# Deferir el cambio de estado y la desactivación del hitbox para evitar errores en consultas físicas
	call_deferred("_set_state", State.HURT)
	if attack_shape:
		attack_shape.set_deferred("disabled", true)
	velocity.y = -80
	await get_tree().create_timer(hurt_time).timeout
	if hp <= 0:
		call_deferred("_set_state", State.DEAD)

# Agrega este método a Player.gd si no está conectado desde el editor
func _on_AttackArea_body_entered(body: Node) -> void:
	# Si el cuerpo tiene método take_damage, le aplicamos daño
	if body and body.has_method("take_damage"):
		body.take_damage(1)
