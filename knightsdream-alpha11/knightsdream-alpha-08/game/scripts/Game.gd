extends Node2D

@onready var pause_menu = get_node_or_null("PauseMenu")

func _ready():
	# Asegura juego activo y oculta el menú si existe
	get_tree().paused = false
	if pause_menu:
		pause_menu.visible = false
	else:
		push_warning("No se encontró el nodo 'PauseMenu' como hijo de Game.")

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if pause_menu:
			if get_tree().paused:
				pause_menu.hide_pause()
			else:
				pause_menu.show_pause()
