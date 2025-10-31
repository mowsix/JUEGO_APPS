extends Control

func _ready():
    $CenterContainer/VBox/Title.text = "Temple Knight"
    $CenterContainer/VBox/Play.pressed.connect(_on_play)
    $CenterContainer/VBox/Options.pressed.connect(_on_options)
    $CenterContainer/VBox/Exit.pressed.connect(_on_exit)

func _on_play():
    Global.reset()
    Global.goto_scene("res://game/scenes/Game.tscn")

func _on_options():
    $CenterContainer/VBox/Title.text = "Temple Knight  —  Options (placeholder)"

func _on_exit():
    get_tree().quit()
