extends Control

@export var next_scene:String = "res://game/scenes/MainMenu.tscn"
@export var hold_time:float = 1.8

func _ready():
    $Label.text = "Temple Knight"
    splash()

func splash() -> void:
    await get_tree().create_timer(hold_time).timeout
    Global.goto_scene(next_scene)
