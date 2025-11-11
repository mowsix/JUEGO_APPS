extends Node2D

@onready var pause_menu = get_node_or_null("PauseMenu")
@onready var fight_sound = $FightMusic
func _ready():
		# Inicia la música de opciones
	_play_game_music()
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
				
func _play_game_music():
	fight_sound.stream = load("res://game/scenes/FightMusic.ogg")
	fight_sound.volume_db = 0
	fight_sound.play()
