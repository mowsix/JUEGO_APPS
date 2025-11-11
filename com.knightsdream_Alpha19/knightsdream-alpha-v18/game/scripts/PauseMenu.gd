extends CanvasLayer

@onready var resume_button: TextureButton = $Resume
@onready var main_menu_button: TextureButton = $MainMenu

var is_active := false

func _ready():
	# Godot 4: procesar aún cuando el árbol está pausado
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	if resume_button:
		resume_button.pressed.connect(_on_resume)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu)

func show_pause():
	if is_active:
		return
	is_active = true
	visible = true
	get_tree().paused = true

func hide_pause():
	if not is_active:
		return
	is_active = false
	visible = false
	get_tree().paused = false

func _on_resume():
	hide_pause()

func _on_main_menu():
	hide_pause()
	Global.goto_scene("res://game/scenes/MainMenu.tscn")

func _unhandled_input(event):
	if event.is_action_pressed("pause") and is_active:
		hide_pause()
