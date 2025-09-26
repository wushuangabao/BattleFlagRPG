class_name SceneManager extends AbstractSystem

@export var packed_scene: PackedSceneDictionary # todo 改成读表，而不是手动配置

# 预加载常用场景，避免频繁加载
# 这些场景在 goto_scene 中第一次实例化之后会被缓存
@export var scene_cached: PackedSceneDictionary

# 缓存常用的场景，避免反复释放加载
var _scene_cache: Dictionary = {}

# 切换到战斗场景前的场景
var _origin_scene: Node

# 当前场景名称
var _current_scene: StringName

func _ready() -> void:
	Game.g_scenes = self
	goto_scene(&"MainMenu")
	print("场景管理器初始化完毕")

# 开始战斗
func start_battle(battle_scene: PackedScene) -> void:
	if get_child_count() > 0:
		_origin_scene = get_child(0)
		remove_child(_origin_scene)
	else:
		push_warning("start_battle but origin scene is null. It should not happen.")
	Game.g_combat.init_with_battle_scene(battle_scene)
	goto_scene(&"BattleScene")

# 回到战斗前的场景
func back_to_origin_scene() -> void:
	if _origin_scene:
		var old_scene = get_child(0)
		remove_child(old_scene)
		old_scene.call_deferred(&"release_on_change_scene")
		add_child(_origin_scene)
		_origin_scene = null
	else:
		push_warning("back_to_origin_scene but origin scene is null. It should not happen.")

# 切换场景
func goto_scene(scene_name: StringName) -> void:
	if _current_scene and _current_scene == scene_name:
		return
	if get_child_count() > 0:
		var old_scene = get_child(0)
		if _scene_cache.has(_current_scene):
			remove_child(old_scene) # 删除当前场景，但不释放内存
		elif old_scene != _origin_scene:
			old_scene.queue_free() # 释放当前场景
	# 尝试用三种方式加载场景：
	# 1 从缓存中取场景
	var scene = _scene_cache.get(scene_name)
	# 2 加载场景，加入缓存
	if not scene and scene_cached.exists(scene_name):
		var packed = scene_cached.get_scene(scene_name)
		scene = packed.instantiate()
		_scene_cache[scene_name] = scene # 加入缓存
	# 3 加载场景，不缓存
	elif not scene and packed_scene.exists(scene_name):
		var packed = packed_scene.get_scene(scene_name)
		scene = packed.instantiate()
	if scene:
		add_child(scene) # 添加新场景到当前节点
		_current_scene = scene_name
