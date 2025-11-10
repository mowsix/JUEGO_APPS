extends CanvasLayer

@onready var pause_menu = get_node_or_null("../PauseMenu")

func _ready():
	print("TouchControls: _ready running")
	_connect_button("Left", "move_left")
	_connect_button("Right", "move_right")
	_connect_button("Jump", "jump")
	_connect_button("Attack", "attack")

	# Conectar pausa (si existe)
	var pause_node = get_node_or_null("Pause")
	if pause_node:
		_connect_pause(pause_node)
	else:
		push_warning("TouchControls: nodo 'Pause' no encontrado.")

# Conecta un botón por nombre a una acción de Input
func _connect_button(node_name: String, action_name: String) -> void:
	var node = get_node_or_null(node_name)
	if not node:
		push_warning("TouchControls: no se encontró el nodo '%s'." % node_name)
		return

	print("TouchControls: conectando '%s' -> action '%s' (type: %s)" % [node_name, action_name, node.get_class()])

	# TouchScreenButton usa signals button_down / button_up
	if node.has_signal("button_down") and node.has_signal("button_up"):
		var cb_down := Callable(self, "_on_button_down").bind(action_name)   # <-- pasar STRING, no ARRAY
		var cb_up := Callable(self, "_on_button_up").bind(action_name)
		node.connect("button_down", cb_down)
		node.connect("button_up", cb_up)
		print("TouchControls: conectado (button_down/button_up) para %s" % node_name)
		return

	# Button / TextureButton usan pressed / released
	if node.has_signal("pressed") and node.has_signal("released"):
		var cb_down2 := Callable(self, "_on_button_down").bind(action_name)  # <-- pasar STRING, no ARRAY
		var cb_up2 := Callable(self, "_on_button_up").bind(action_name)
		node.connect("pressed", cb_down2)
		node.connect("released", cb_up2)
		print("TouchControls: conectado (pressed/released) para %s" % node_name)
		return

	push_warning("TouchControls: el nodo '%s' no tiene señales esperadas (button_down/button_up o pressed/released)." % node_name)

func _on_button_down(action_name: String) -> void:
	print("TouchControls: _on_button_down ->", action_name)
	Input.action_press(action_name)

func _on_button_up(action_name: String) -> void:
	print("TouchControls: _on_button_up ->", action_name)
	Input.action_release(action_name)

# Manejo específico del botón de pausa (reusa _on_pause_pressed)
func _connect_pause(node: Node) -> void:
	if node.has_signal("button_down") and node.has_signal("button_up"):
		node.connect("button_down", Callable(self, "_on_pause_pressed"))
		node.connect("button_up", Callable(self, "_on_pause_released"))
		return
	if node.has_signal("pressed") and node.has_signal("released"):
		node.connect("pressed", Callable(self, "_on_pause_pressed"))
		node.connect("released", Callable(self, "_on_pause_released"))
		return
	push_warning("TouchControls: el nodo 'Pause' no tiene señales esperadas.")

func _on_pause_pressed():
	if pause_menu:
		if get_tree().paused:
			pause_menu.hide_pause()
		else:
			pause_menu.show_pause()
	else:
		push_warning("No se encontró '../PauseMenu' para controlar la pausa.")

func _on_pause_released():
	Input.action_release("pause")
