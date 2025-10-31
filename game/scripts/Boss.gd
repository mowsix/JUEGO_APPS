extends CharacterBody2D

@export var gravity:float = 900.0
@export var health:int = 20
@export var move_speed:float = 25.0

var direction:int = 1

func _ready():
    $Sprite.modulate = Color(0.8, 0.4, 1.0, 1.0)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y += gravity * delta
    velocity.x = direction * move_speed
    move_and_slide()

func take_damage(dmg:int):
    health -= dmg
    if health <= 0:
        $Label.text = "¡Jefe derrotado!"
        $Label.visible = true
        Global.add_score(100)
        queue_free()

func _on_BodyArea_body_entered(body):
    if body.has_method("take_damage"):
        body.take_damage(1)
