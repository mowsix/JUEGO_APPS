# KillsScore.gd  (adjúntalo al nodo Label "KillsValue")
extends Label

func _ready() -> void:
	# Godot 4: actualiza aunque el juego esté en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

	# pinta valor inicial
	text = str(Global.kills)

	# conecta a la señal para refrescar automáticamente
	if not Global.kills_changed.is_connected(_on_kills_changed):
		Global.kills_changed.connect(_on_kills_changed)

func _on_kills_changed(new_value:int) -> void:
	text = str(new_value)
