extends Button

var _scene_manager : Node

func _ready() -> void:
	_scene_manager = get_node(Game.scene_manager_path())

func _on_pressed() -> void:
	_scene_manager.goto_scene("BigMap")
