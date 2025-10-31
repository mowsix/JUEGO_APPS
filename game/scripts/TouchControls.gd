extends CanvasLayer

func _ready():
    $Left.button_down.connect(func(): Input.action_press("move_left"))
    $Left.button_up.connect(func(): Input.action_release("move_left"))
    $Right.button_down.connect(func(): Input.action_press("move_right"))
    $Right.button_up.connect(func(): Input.action_release("move_right"))
    $Jump.button_down.connect(func(): Input.action_press("jump"))
    $Jump.button_up.connect(func(): Input.action_release("jump"))
    $Attack.button_down.connect(func(): Input.action_press("attack"))
    $Attack.button_up.connect(func(): Input.action_release("attack"))
    $Pause.button_down.connect(func(): Input.action_press("pause"))
    $Pause.button_up.connect(func(): Input.action_release("pause"))
