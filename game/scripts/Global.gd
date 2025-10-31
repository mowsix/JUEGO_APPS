extends Node

var score:int = 0
var mana:float = 100.0
const MAX_MANA:float = 100.0

func _ready():
    ensure_input_map()

func ensure_input_map():
    var actions = {
        "move_left": [KEY_A, KEY_LEFT],
        "move_right": [KEY_D, KEY_RIGHT],
        "jump": [KEY_W, KEY_SPACE],
        "attack": [KEY_J],
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

func goto_scene(path:String):
    get_tree().change_scene_to_file(path)

func pause_game():
    get_tree().paused = true

func resume_game():
    get_tree().paused = false

func toggle_pause():
    get_tree().paused = not get_tree().paused

func _unhandled_input(event):
    if event.is_action_pressed("pause"):
        toggle_pause()
