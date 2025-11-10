extends Control

@export var next_scene: String = "res://game/scenes/MainMenu.tscn"
@export var hold_time: float = 9.0

@onready var logo: TextureRect = $TextureRect
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var fade: ColorRect = $Fade

func _ready():
	# Fade inicial desde negro → visible
	fade.visible = true
	fade.modulate.a = 1.0

	# Cargar música
	var music_path = "res://game/scenes/SplashMusic.ogg"
	if ResourceLoader.exists(music_path):
		audio.stream = load(music_path)
		audio.play()
	else:
		push_error("No se encontró el archivo de música: " + music_path)

	await fade_in_scene()
	await get_tree().create_timer(hold_time - 2.0).timeout
	await fade_out_scene()
	Global.goto_scene(next_scene)

# ⬛ Hace que el splash entre en pantalla (fade-in)
func fade_in_scene():
	var fade_time := 0.5
	var elapsed := 0.0
	while elapsed < fade_time:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		var t = clamp(elapsed / fade_time, 0.0, 1.0)
		fade.modulate.a = 1.0 - t  # Va de negro a visible


# ⬛ Hace que toda la pantalla y sonido se desvanezcan
func fade_out_scene():
	var fade_time := 2.5
	var elapsed := 0.0
	while elapsed < fade_time:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		var t = clamp(elapsed / fade_time, 0.0, 1.0)
		fade.modulate.a = t
		if audio:
			audio.volume_db = lerp(0.0, -40.0, t)
