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

func _ready() -> void:
	var scene_viewer = sceneviewer_scene.instantiate()
	_scene_navigator = SceneNavigator.new(scene_viewer as SceneViewer)
	_scene_cache[sceneviewer_scene] = scene_viewer
	Game.g_scenes = self
	goto_scene(main_scene)
	print("场景管理器初始化完毕")

# SceneViewer 显示场景
func show_scene(scene_data: SceneData) -> void:
	if _current_scene != sceneviewer_scene:
		await goto_scene(sceneviewer_scene)
	else:
		fade_rect_anim.play(&"fade_out")
		await fade_rect_anim.animation_finished
	if (_scene_cache[sceneviewer_scene] as SceneViewer).background_rect == null:
		await _scene_cache[sceneviewer_scene].ready
	_scene_navigator.show_scene(scene_data)
	fade_rect_anim.play(&"fade_in")

# SceneViewer 压入场景
func push_scene(scene_data: SceneData) -> void:
	if _current_scene != sceneviewer_scene:
		return
	fade_rect_anim.play(&"fade_out")
	await fade_rect_anim.animation_finished
	_scene_navigator.push_scene(scene_data)
	fade_rect_anim.play(&"fade_in")

# SceneViewer 弹出场景
func pop_scene() -> void:
	if _current_scene != sceneviewer_scene:
		return
	fade_rect_anim.play(&"fade_out")
	await fade_rect_anim.animation_finished
	_scene_navigator.pop_scene()
	fade_rect_anim.play(&"fade_in")

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
