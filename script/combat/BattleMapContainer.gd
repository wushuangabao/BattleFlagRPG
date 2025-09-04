class_name BattleMapContainer
extends SubViewport

@export var packed_scene: PackedSceneDictionary # 每添加一个战斗地图，都要在这个字典里加上（todo 改成读表加载）

# 当前地图名称
var _current_scene: String

# 开始战斗（切换地图）
func loadScene_battleMap(scene_name: String) -> Node:
	if _current_scene and _current_scene == scene_name:
		return null
	if get_child_count() > 0:
		get_child(0).queue_free() # 释放当前场景
	# 动态加载场景
	if packed_scene.exists(scene_name):
		var packed = packed_scene.get_scene(scene_name)
		var scene = packed.instantiate()
		if scene:
			_current_scene = scene_name
			scene.battle_map_ready.connect(func():
				get_parent()._on_battle_map_loaded())
			add_child(scene)
			return scene
	else:
		push_error("loadScene_battleMap, not find ", scene_name)
	return null
