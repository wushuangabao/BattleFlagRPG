extends Button

func _on_pressed() -> void:
	Game.g_scenes.goto_scene(load("res://scene/map/BigMap.tscn"))
