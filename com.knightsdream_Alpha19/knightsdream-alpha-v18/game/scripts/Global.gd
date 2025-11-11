extends Node

var score:int = 0
var mana:float = 100.0
const MAX_MANA:float = 100.0

# --- contador de muertes (empieza en 0) ---
var kills:int = 0
signal kills_changed(new_value:int)

func _ready():
	ensure_input_map()
	# emite el valor inicial para que cualquier UI pueda pintarlo
	emit_signal("kills_changed", kills)

func ensure_input_map():
	var actions = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_W, KEY_SPACE],
		"attack": [KEY_F],
		"pause": [KEY_ESCAPE, KEY_P]
	}
	for action in actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).size() == 0:
			for sc in actions[action]:
				var ev := InputEventKey.new()
				ev.physical_keycode = sc
				InputMap.action_add_event(action, ev)

func reset():
	score = 0
	mana = MAX_MANA
	# resetear kills a 0 y avisar a la UI
	kills = 0
	emit_signal("kills_changed", kills)

func add_score(n:int=1):
	score += n

func can_spend_mana(cost:float) -> bool:
	return mana >= cost

func spend_mana(cost:float) -> bool:
	if mana >= cost:
		mana -= cost
		return true
	return false

func refill_mana(n:float):
	mana = clamp(mana + n, 0.0, MAX_MANA)

# --- sumar kills y notificar ---
func add_kill(n:int=1) -> void:
	kills += n
	emit_signal("kills_changed", kills)

# Versión segura y con debug de goto_scene
func goto_scene(path:String) -> void:
	print("[Global] goto_scene -> ", path)
	if not ResourceLoader.exists(path):
		push_error("[Global] goto_scene: el archivo no existe: %s" % path)
		return
	var res := ResourceLoader.load(path)
	if res == null:
		push_error("[Global] goto_scene: no se pudo cargar recurso: %s" % path)
		return
	if not res is PackedScene:
		push_error("[Global] goto_scene: recurso no es PackedScene: %s" % path)
		return
	print("[Global] Escena cargada correctamente, cambiando...")
	var error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("[Global] goto_scene: error al cambiar escena: %s (código: %d)" % [path, error])
