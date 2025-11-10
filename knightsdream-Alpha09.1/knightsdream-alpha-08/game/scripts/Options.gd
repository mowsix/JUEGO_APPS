extends Control

@onready var back_button = $BackButton
@onready var options_sound = $OptionsSound
@onready var btn_activado = $Activado
@onready var btn_desactivado = $Desactivado

var sonido_activo: bool = true

func _ready():
	btn_activado.pressed.connect(_on_activado_pressed)
	btn_desactivado.pressed.connect(_on_desactivado_pressed)
	back_button.pressed.connect(_on_back_pressed)

	_update_visuals()
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)

	# Inicia la música de opciones
	_play_options_music()

func _play_options_music():
	options_sound.stream = load("res://game/scenes/OptionsSound.ogg")
	options_sound.volume_db = 0
	options_sound.play()

func _on_activado_pressed():
	sonido_activo = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	_update_visuals()

func _on_desactivado_pressed():
	sonido_activo = false
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	_update_visuals()

func _on_back_pressed():
	await _fade_out()
	get_tree().change_scene_to_file("res://game/scenes/MainMenu.tscn")

func _update_visuals():
	if sonido_activo:
		btn_activado.modulate = Color(1.5, 1.5, 1.0, 1.0)
		btn_desactivado.modulate = Color(0.6, 0.6, 0.6, 1.0)
	else:
		btn_activado.modulate = Color(0.6, 0.6, 0.6, 1.0)
		btn_desactivado.modulate = Color(1.5, 1.5, 1.0, 1.0)

func _fade_out():
	var fade_time := 2.0
	var elapsed := 0.0

	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.size = get_viewport_rect().size
	add_child(fade_rect)
	fade_rect.move_to_front()

	var bus_index = AudioServer.get_bus_index("Master")
	var initial_volume = AudioServer.get_bus_volume_db(bus_index)
	var initial_music_volume = options_sound.volume_db

	while elapsed < fade_time:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

		fade_rect.color.a = clamp(elapsed / fade_time, 0.0, 1.0)
		var new_volume = lerp(initial_volume, -40.0, elapsed / fade_time)
		AudioServer.set_bus_volume_db(bus_index, new_volume)
		options_sound.volume_db = lerp(initial_music_volume, -40.0, elapsed / fade_time)

	options_sound.stop()
	AudioServer.set_bus_volume_db(bus_index, initial_volume)
