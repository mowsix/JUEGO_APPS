extends TextureRect

@export var fade_in_speed: float = 0.4
@export var fade_out_speed: float = 0.3
@export var pulse_speed: float = 3.0

var time := 0.0
var fading_in := true
var fading_out := false

func _ready():
	modulate.a = 0.0  # Comienza invisible

func _process(delta):
	time += delta

	# Fade in del logo
	if fading_in:
		modulate.a = min(1.0, modulate.a + delta * fade_in_speed)
		if modulate.a >= 1.0:
			fading_in = false

	# Brillo pulsante mientras está visible
	if not fading_in and not fading_out:
		modulate = Color(1, 1, 1, modulate.a) * (1.0 + 0.05 * sin(time * pulse_speed))

	# Fade out cuando se activa desde el nodo padre
	if fading_out:
		modulate.a = max(0.0, modulate.a - delta * fade_out_speed)

func start_fade_out():
	fading_out = true
