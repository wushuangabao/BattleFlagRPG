extends Button

var _scene_manager : Node

func _ready() -> void:
	_scene_manager = get_node("/root/Game/GameRoot")

func _on_pressed() -> void:
	_scene_manager.goto_scene("BattleScene")
