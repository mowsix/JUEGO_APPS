extends CanvasLayer

func _process(_delta):
	$Margin/Score.text = "Puntos: %d" % Global.score
	$Margin/Mana.value = Global.mana
	$Margin/Mana.max_value = Global.MAX_MANA
