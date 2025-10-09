class_name SceneManager extends AbstractSystem

@export var main_scene: PackedScene
@export var battle_scene: PackedScene
@export var sceneviewer_scene: PackedScene

@onready var fade_rect_anim: AnimationPlayer = $"../AnimationPlayer"

# 缓存常用的场景，避免反复释放加载
var _scene_cache: Dictionary[PackedScene, Node] = {}

# 切换到战斗场景前的场景
var _origin_scene: Node

# 当前场景
var _current_scene: PackedScene = null

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
	if op != SceneOp.POP and scene_data == null:
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
	_navigate_scene(SceneOp.SHOW, scene_data)

func push_scene(scene_data: SceneData) -> void:
	_navigate_scene(SceneOp.PUSH, scene_data)

func pop_scene() -> void:
	if _scene_navigator.is_root_scene():
		var packed_scene := _scene_navigator.current_scene().back_to_map_scene
		if packed_scene:
			Game.g_scenes.goto_scene(packed_scene)
			_scene_navigator.stack.clear()
	else:
		_navigate_scene(SceneOp.POP)

func clear_scene() -> void:
	_scene_navigator.stack.clear()

# 开始战斗
func start_battle(battle_map: PackedScene) -> void:
	if get_child_count() > 0:
		_origin_scene = get_child(0)
		remove_child(_origin_scene)
	else:
		push_warning("start_battle but origin scene is null. It should not happen.")
	Game.g_combat.init_with_battle_scene(battle_map)
	goto_scene(battle_scene)

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
func goto_scene(p_scene: PackedScene) -> void:
	if _current_scene and _current_scene == p_scene:
		return
	if _current_scene != null:
		if fade_rect_anim.is_playing() == false:
			fade_rect_anim.play(&"fade_out")
		await fade_rect_anim.animation_finished
	if get_child_count() > 0:
		var old_scene = get_child(0)
		if _scene_cache.has(_current_scene) == false and old_scene != _origin_scene:
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
		add_child(scene)
		_current_scene = p_scene
