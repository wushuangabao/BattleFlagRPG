extends Node
@export var packed_scene: PackedSceneDictionary # todo 改成读表，而不是手动配置

# 缓存常用的场景，避免反复释放加载
var _scene_cache: Dictionary = {}

# 当前场景名称
var _current_scene: String

# 开始战斗
func start_battle(battle_name: String) -> void:
	Game.g_combat.cur_battle_name = battle_name
	goto_scene("BattleScene")

# 切换场景
func goto_scene(scene_name: String) -> void:
	if _current_scene and _current_scene == scene_name:
		return
	if get_child_count() > 0:
		if _scene_cache.has(_current_scene):
			remove_child(get_child(0)) # 删除当前场景，但不释放内存
		else:
			get_child(0).queue_free() # 释放当前场景
	# 尝试用三种方式加载场景：
	# 1 从缓存中取场景
	var scene = _scene_cache.get(scene_name)
	# 2 用预加载的 PackedScene 实例化场景
	if not scene and Game.scene_cached.has(scene_name):
		var packed = Game.scene_cached[scene_name]
		if packed:
			scene = packed.instantiate()
			_scene_cache[scene_name] = scene # 加入缓存
	# 3 动态加载场景
	if not scene and packed_scene.exists(scene_name):
		var packed = packed_scene.get_scene(scene_name)
		scene = packed.instantiate()
	if scene:
		add_child(scene) # 添加新场景到当前节点
		_current_scene = scene_name
