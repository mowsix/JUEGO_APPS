extends CanvasLayer

func _ready():
    visible = false
    $Panel/VBox/Resume.pressed.connect(_on_resume)
    $Panel/VBox/Restart.pressed.connect(_on_restart)
    $Panel/VBox/MainMenu.pressed.connect(_on_main_menu)

func show_pause():
    visible = true
    Global.pause_game()

func hide_pause():
    visible = false
    Global.resume_game()

func _on_resume():
    hide_pause()

func _on_restart():
    var current = get_tree().current_scene.scene_file_path
    Global.resume_game()
    Global.goto_scene(current)

func _on_main_menu():
    Global.resume_game()
    Global.goto_scene("res://game/scenes/MainMenu.tscn")
