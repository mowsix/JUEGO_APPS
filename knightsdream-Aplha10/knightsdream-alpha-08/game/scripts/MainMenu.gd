extends Control

func _ready():
	$Play.pressed.connect(_on_play)
	$Options.pressed.connect(_on_options)
	$Exit.pressed.connect(_on_exit)
	$Creditos.pressed.connect(_on_credits)

func _on_play():
	Global.reset()
	Global.goto_scene("res://game/scenes/Game.tscn")

func _on_options():
	Global.goto_scene("res://game/scenes/Options.tscn")

func _on_exit():
	get_tree().quit()

func _on_credits():
	Global.goto_scene("res://game/scenes/Credits.tscn")
