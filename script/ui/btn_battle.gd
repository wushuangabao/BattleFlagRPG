extends Button

func _on_pressed() -> void:
	Game.g_scenes.start_battle(load("res://asset/battle/map/test_battle_map.tscn"))
