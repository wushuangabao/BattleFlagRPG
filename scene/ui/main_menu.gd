extends VBoxContainer

func _on_btn_new_game_pressed() -> void:
	print("_on_btn_new_game_pressed")
	if Game.g_scenes == null or Game.g_runner == null or Game.g_actors == null:
		return
	Game.g_actors.init_all_characters()
	var first := load("res://asset/scene/village.tres") as SceneData
	Game.g_scenes.push_scene(first)
	if Game.g_runner:
		print("start story")
		Game.g_runner.start(preload("res://asset/story/story_main.tres"))
