extends AnimatedSprite2D

func _ready() -> void:
	hide()

func on_focus() -> void:
	show()
	play(&"default", 1.4)

func lost_focus() -> void:
	stop()
	hide()
