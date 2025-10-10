class_name SceneManager extends AbstractSystem

@export var main_scene: PackedScene
@export var battle_scene: PackedScene
@export var sceneviewer_scene: PackedScene

@onready var fade_rect_anim: AnimationPlayer = $"../AnimationPlayer"

# 缓存常用的场景，避免反复释放加载
var _scene_cache: Dictionary[PackedScene, Node] = {}

# 切换到战斗场景前的场景
var origin_path: String = ""

# 当前场景
var _current_scene: PackedScene = null

# 上一个场景
var _last_scene: PackedScene = null

# 场景导航
var _scene_navigator: SceneNavigator

# 统一场景操作枚举
enum SceneOp { SHOW, PUSH, POP }

func _ready() -> void:
	var scene_viewer = sceneviewer_scene.instantiate()
	_scene_navigator = SceneNavigator.new(scene_viewer as SceneViewer)
	_scene_cache[sceneviewer_scene] = scene_viewer
	Game.g_scenes = self
	goto_scene(main_scene)
	print("场景管理器初始化完毕")

func push_scene_data(scene_data: SceneData) -> void:
	_scene_navigator.stack.push_back(scene_data)

## 统一的 SceneViewer 场景导航方法
func _navigate_scene(op: int, scene_data: SceneData = null) -> void:
	if op == SceneOp.PUSH and scene_data == null:
		push_error("navigate_scene but scene_data is null.")
		return
	var viewer := _scene_cache.get(sceneviewer_scene, null) as SceneViewer
	if viewer == null:
		push_error("navigate_scene but viewer is null.")
		return
	var in_viewer := _current_scene == sceneviewer_scene
	if not in_viewer:
		await goto_scene(sceneviewer_scene)
	if viewer.background_rect == null:
		await viewer.ready
	if in_viewer:
		fade_rect_anim.play(&"fade_out")
		await fade_rect_anim.animation_finished
	match op:
		SceneOp.SHOW:
			_scene_navigator.show_scene(scene_data)
		SceneOp.PUSH:
			_scene_navigator.push_scene(scene_data)
		SceneOp.POP:
			_scene_navigator.pop_scene()
		_:
			push_warning("navigate_scene: unknown op " + str(op))
			return
	fade_rect_anim.play(&"fade_in")
	_scene_navigator.on_enter_scene_or_story()

func show_scene(scene_data: SceneData) -> void:
	await _navigate_scene(SceneOp.SHOW, scene_data)

func push_scene(scene_data: SceneData) -> void:
	await _navigate_scene(SceneOp.PUSH, scene_data)

func pop_scene() -> void:
	if _scene_navigator.is_root_scene():
		var packed_scene := _scene_navigator.current_scene().back_to_map_scene
		if packed_scene:
			await Game.g_scenes.goto_scene(packed_scene)
			_scene_navigator.stack.clear()
	else:
		await _navigate_scene(SceneOp.POP)

func clear_scene() -> void:
	_scene_navigator.stack.clear()

# 开始战斗
func start_battle(battle_map: PackedScene, origin_ps = null) -> void:
	if origin_ps and origin_ps is PackedScene:
		_set_origin_scene(origin_ps)
	elif get_child_count() > 0:
		var origin_scene = get_child(0)
		origin_path = _current_scene.resource_path
		if origin_scene.has_node(^"TempScene"):
			_scene_cache[_current_scene] = origin_scene # 加入缓存
	else:
		push_warning("start_battle but origin scene is null. It should not happen.")
	await goto_scene(battle_scene)
	if origin_ps and origin_ps is PackedScene:
		_last_scene = origin_ps
	Game.g_combat.init_with_battle_scene(battle_map)

# 读档时设置战斗前的场景
func _set_origin_scene(origin_ps: PackedScene) -> void:
	origin_path = origin_ps.resource_path
	var origin_scene = null
	if _scene_cache.has(origin_ps):
		origin_scene = _scene_cache.get(origin_ps, null)
	if origin_scene == null:
		origin_scene = origin_ps.instantiate()
		if origin_scene:
			_scene_cache[origin_ps] = origin_scene

# 回到战斗前的场景
func back_to_origin_scene() -> void:
	if not origin_path.is_empty() and _last_scene != null:
		var old_scene = get_child(0)
		remove_child(old_scene)
		if _last_scene == sceneviewer_scene:
			(old_scene as BattleScene).release_on_change_scene()
			_navigate_scene(SceneOp.SHOW, _scene_navigator.stack.back())
		else:
			goto_scene(_last_scene)
	else:
		push_warning("back_to_origin_scene but origin scene is null. It should not happen.")

# 切换场景
func goto_scene(p_scene: PackedScene) -> void:
	if _current_scene != null:
		if fade_rect_anim.is_playing() == false:
			fade_rect_anim.play(&"fade_out")
		await fade_rect_anim.animation_finished
	if get_child_count() > 0:
		var old_scene = get_child(0)
		if _current_scene == battle_scene:
			(old_scene as BattleScene).release_on_change_scene()
		if _scene_cache.has(_current_scene) == false:
			old_scene.queue_free()  # 释放当前场景
		else:
			remove_child(old_scene) # 删除当前场景，但不释放内存
	var scene = null
	if _scene_cache.has(p_scene):
		scene = _scene_cache.get(p_scene, null)
	if not scene:
		scene = p_scene.instantiate()
		if scene and scene.has_node(^"TempScene") == false:
			_scene_cache[p_scene] = scene # 加入缓存
	if scene:
		if _current_scene != null:
			fade_rect_anim.play(&"fade_in")
			if _current_scene == battle_scene and not Game.g_combat.scene.is_released_ok:
				await Game.g_combat.scene.battle_scene_released_ok
		add_child(scene)
		if p_scene == battle_scene and Game.g_combat.scene == null:
			await scene.ready
		if _current_scene != null:
			_last_scene = _current_scene
		_current_scene = p_scene
