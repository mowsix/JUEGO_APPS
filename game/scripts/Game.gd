extends Node2D

func _ready():
    Global.resume_game()
    $HUD.visible = true
    $PauseMenu.visible = false

func _unhandled_input(event):
    if event.is_action_pressed("pause"):
        if get_tree().paused:
            $PauseMenu.hide_pause()
        else:
            $PauseMenu.show_pause()
