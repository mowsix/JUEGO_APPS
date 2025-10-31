extends CharacterBody2D

@export var move_speed:float = 40.0
@export var gravity:float = 900.0
@export var patrol_range:float = 80.0
@export var health:int = 2

var origin_x:float
var direction:int = 1

func _ready():
    origin_x = global_position.x
    $Sprite.modulate = Color(1.0, 0.6, 0.6, 1.0)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y += gravity * delta
    velocity.x = direction * move_speed
    move_and_slide()
    if abs(global_position.x - origin_x) > patrol_range:
        direction *= -1

func take_damage(dmg:int):
    health -= dmg
    if health <= 0:
        queue_free()
        Global.add_score(10)

func _on_HurtArea_body_entered(body):
    if body.has_method("take_damage"):
        body.take_damage(1)
