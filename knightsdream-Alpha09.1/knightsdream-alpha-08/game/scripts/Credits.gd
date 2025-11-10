extends Control

@onready var label = $Label
@export var scroll_speed: float = 40.0
@export var next_scene: String = "res://game/scenes/MainMenu.tscn"

var _is_fading := false

func _ready():
	# Posicionar el texto al inicio (debajo de la pantalla)
	label.position.y = get_viewport_rect().size.y
	# Conectar botón "Atrás"
	$BackButton.pressed.connect(_on_back_pressed)

func _process(delta):
	# Mover el texto hacia arriba
	label.position.y -= scroll_speed * delta

	# Si termina el scroll y aún no se hizo fade, cambiar de escena
	if not _is_fading and label.position.y + label.size.y < 0:
		_fade_to_main_menu()

func _on_back_pressed():
	# Si presiona el botón "Atrás"
	if not _is_fading:
		_fade_to_main_menu()

func _fade_to_main_menu():
	_is_fading = true  # evitar múltiples llamadas
	# Crear el rectángulo de fade
	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	add_child(fade_rect)
	fade_rect.size = get_viewport_rect().size
	fade_rect.z_index = 10  # asegurarse que esté encima

	var fade_time := 1.5
	var elapsed := 0.0

	while elapsed < fade_time:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		fade_rect.color.a = clamp(elapsed / fade_time, 0.0, 1.0)

	get_tree().change_scene_to_file(next_scene)
