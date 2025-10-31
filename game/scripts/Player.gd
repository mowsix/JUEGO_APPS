extends CharacterBody2D

@export var move_speed:float = 140.0
@export var jump_velocity:float = -280.0
@export var gravity:float = 900.0
@export var attack_cost:float = 10.0
@export var attack_time:float = 0.15

var attack_cooldown:bool = false

signal player_hurt
signal player_attack

func _ready():
    $Sprite.modulate = Color(0.9, 0.9, 1.0, 1.0)
    $AttackArea/CollisionShape2D.disabled = true

func _physics_process(delta):
    if not is_on_floor():
        velocity.y += gravity * delta
    var dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    velocity.x = dir * move_speed
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
    move_and_slide()
    if Input.is_action_just_pressed("attack"):
        _try_attack()

func _try_attack():
    if attack_cooldown:
        return
    if not Global.spend_mana(attack_cost):
        return
    attack_cooldown = true
    $AttackArea/CollisionShape2D.disabled = false
    emit_signal("player_attack")
    await get_tree().create_timer(attack_time).timeout
    $AttackArea/CollisionShape2D.disabled = true
    await get_tree().create_timer(0.2).timeout
    attack_cooldown = false

func take_damage(amount:int=1):
    emit_signal("player_hurt")
    Global.mana = max(0.0, Global.mana - 5.0)

func _on_AttackArea_body_entered(body):
    if body.has_method("take_damage"):
        body.take_damage(1)
        Global.add_score(5)
