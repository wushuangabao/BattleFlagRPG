class_name BattleMapContainer
extends SubViewport

@export var packed_scene: PackedSceneDictionary # 每添加一个战斗地图，都要在这个字典里加上（todo 改成在StoryGraph里的BattleNode中配置）

# 当前地图名称
var _current_scene: String

# 开始战斗（切换地图）
func loadScene_battleMap(scene_name: StringName) -> BattleMap:
	if _current_scene and _current_scene == scene_name:
		return get_child(0)
	# 动态加载场景
	if packed_scene.exists(scene_name):
		var scene = packed_scene.get_scene(scene_name).instantiate()
		if scene:
			_current_scene = scene_name
			add_child(scene)
			await scene.battle_map_ready
			return scene
	else:
		push_error("loadScene_battleMap, not find ", scene_name)
	return null

func release_battleMap() -> void:
	if get_child_count() > 0:
		_current_scene = ""
		get_child(0).queue_free() # 释放当前场景
