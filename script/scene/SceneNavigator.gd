class_name SceneNavigator

static var viewer: SceneViewer = null
var stack: Array[SceneData] = []

func _init(scene_viewer: SceneViewer) -> void:
	viewer = scene_viewer

func show_scene(data: SceneData) -> void:
	# 清空栈，直接显示一个场景
	stack.clear()
	stack.append(data)
	(viewer as Node).call("set_scene_data", data)
	_show_viewer()

func push_scene(data: SceneData) -> void:
	if data == null:
		return
	stack.push_back(data)
	(viewer as Node).call("set_scene_data", data)
	_show_viewer()

func pop_scene() -> void:
	if stack.size() <= 1:
		# 已经是根场景了：可选择关闭 viewer 或保持
		# 这里选择保持在根不再弹出
		return
	stack.pop_back()
	var top : SceneData = stack.back()
	(viewer as Node).call("set_scene_data", top)
	_show_viewer()

func current_scene() -> SceneData:
	return stack.back() if stack.size() > 0 else null	

func _show_viewer() -> void:
	if viewer:
		viewer.visible = true
