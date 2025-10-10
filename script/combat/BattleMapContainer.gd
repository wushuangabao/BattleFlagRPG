class_name BattleMapContainer
extends SubViewport

# 当前地图场景资源
var _current_scene: PackedScene

# 开始战斗（切换地图）
func loadScene_battleMap(scene_map: PackedScene) -> BattleMap:
	if _current_scene and _current_scene == scene_map:
		return get_child(0)
	# 动态加载场景
	var scene = scene_map.instantiate()
	if scene:
		if not scene is BattleMap:
			push_error("加载失败，这个场景不是BattleMap：", scene_map.get_path())
			return null
		_current_scene = scene_map
		if get_child_count() > 0:
			get_child(0).queue_free() # 释放当前场景
		add_child(scene)
		await scene.battle_map_ready
		return scene
	push_error("无法实例化场景：", scene_map.get_path())
	return null

func release_battleMap() -> void:
	if get_child_count() > 0:
		_current_scene = null
		get_child(0).free() # 释放当前场景

func get_cur_scene_path() -> String:
	if not _current_scene:
		return ""
	return _current_scene.get_path()
