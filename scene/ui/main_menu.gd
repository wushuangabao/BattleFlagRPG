extends VBoxContainer

func _on_btn_new_game_pressed() -> void:
	print("_on_btn_new_game_pressed")
	if Game.g_scenes == null:
		return
	var first := load("res://asset/scene/village.tres") as SceneData
	Game.g_scenes.show_scene(first)
	#if Game.g_runner:
		#print("start story")
		#Game.g_runner.start(preload("res://asset/story/story_main.tres"))
