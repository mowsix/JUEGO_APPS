extends AudioStreamPlayer

func _ready():
	play()

func _on_finished():
	play()  # vuelve a iniciar automáticamente
