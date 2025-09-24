extends VBoxContainer

func _on_btn_new_game_pressed() -> void:
	print("_on_btn_new_game_pressed")
	if Game.g_runner:
		print("start story")
		Game.g_runner.start(preload("res://asset/story/story_main.tres"))
