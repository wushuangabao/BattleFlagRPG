extends Button

func _on_pressed() -> void:
	Game.g_scenes.start_battle(&"test")
