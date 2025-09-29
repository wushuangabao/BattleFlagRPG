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

func push_scene(data: SceneData) -> void:
	if data == null:
		return
	stack.push_back(data)
	(viewer as Node).call("set_scene_data", data)

func pop_scene() -> void:
	if stack.size() <= 1:
		# 已经是根场景了：可选择关闭 viewer 或保持
		# 这里选择保持在根不再弹出
		return
	stack.pop_back()
	var top : SceneData = stack.back()
	(viewer as Node).call("set_scene_data", top)

func current_scene() -> SceneData:
	return stack.back() if stack.size() > 0 else null	

func is_root_scene() -> bool:
	return stack.size() == 1

func on_enter_scene_or_story() -> bool:
	if viewer.current_data.story_choices.size() > 0:
		if Game.g_runner and Game.g_runner.graph:
			var cur_story_graph = Game.g_runner.graph
			var valid_choices: Array[Choice] = []
			for choice in viewer.current_data.story_choices:
				if choice.story_graph == cur_story_graph:
					valid_choices.append(choice.associate_c)
			if valid_choices.size() > 0:
				var chosen_i = randi_range(0, valid_choices.size() - 1)
				if Game.g_runner.choose(valid_choices[chosen_i]):
					return true
	viewer.show_buttons()
	return false
