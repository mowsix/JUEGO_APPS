extends TextureRect

@export var pulse_speed := 2.0
var t := 0.0

func _process(delta):
	t += delta * pulse_speed
	modulate.a = 0.8 + 0.2 * sin(t)
