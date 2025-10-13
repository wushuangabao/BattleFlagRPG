extends GridContainer

func _on_btnBattle_pressed() -> void:
	Game.g_scenes.start_battle(load("res://asset/battle/map/test_battle_map.tscn"))


func _on_btnBigmap_pressed() -> void:
	Game.g_scenes.goto_scene(load("res://scene/map/BigMap.tscn"))


func _on_btnParty_pressed() -> void:
	Game.g_scenes.goto_scene(load("res://scene/ui/PartyPanel.tscn"))
