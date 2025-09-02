class_name BattleMapContainer
extends SubViewport

@export var packed_scene: PackedSceneDictionary

# 当前地图名称
var _current_scene: String

# 开始战斗（切换地图）
func start_battle(scene_name: String) -> void:
	if _current_scene and _current_scene == scene_name:
		return
	if get_child_count() > 0:
		get_child(0).queue_free() # 释放当前场景
	# 动态加载场景
	if packed_scene.exists(scene_name):
		var packed = packed_scene.get_scene(scene_name)
		var scene = packed.instantiate()
		if scene:
			add_child(scene)
			_current_scene = scene_name
