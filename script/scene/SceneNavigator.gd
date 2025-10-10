class_name SceneNavigator

static var viewer: SceneViewer = null
var stack: Array[SceneData] = []

func _init(scene_viewer: SceneViewer) -> void:
	viewer = scene_viewer

# 在栈中寻找并显示场景
func show_scene(data: SceneData = null) -> void:
	if data == null:
		data = stack.back()
	var index := stack.find(data)
	if index == -1:
		stack.clear()
		stack.append(data)
		(viewer as Node).call("set_scene_data", data)
		return
	stack = stack.slice(0, index + 1)
	assert(stack.back() == data)
	(viewer as Node).call("set_scene_data", data)

func push_scene(data: SceneData) -> void:
	if data == null:
		return
	stack.push_back(data)
	(viewer as Node).call("set_scene_data", data)

func pop_scene() -> void:
	if stack.size() <= 1:
		return
	stack.pop_back()
	var top : SceneData = stack.back()
	(viewer as Node).call("set_scene_data", top)

func current_scene() -> SceneData:
	return stack.back() if stack.size() > 0 else null	

func is_root_scene() -> bool:
	return stack.size() == 1

func on_enter_scene_or_story() -> bool:
	if Game.g_runner and Game.g_runner.graph_manager and Game.g_runner.active_session_id.is_empty():
		var valid_choices = []
		for graph in Game.g_runner.graph_manager.get_valid_graphs():
			var choice_node := graph["current"] as ChoiceNode
			if choice_node.triggers.has(viewer.current_data):
				var choice := (choice_node.choices[choice_node.triggers[viewer.current_data]]) as Choice
				if choice.condition == null or choice.condition.evaluate(graph["state"]):
					var choice_data := {
						"graph": graph["graph"],
						"choice": choice
					}
					valid_choices.append(choice_data)
		if valid_choices.size() > 0:
			var chosen_i = randi_range(0, valid_choices.size() - 1)
			var chosen = valid_choices[chosen_i]
			if Game.g_runner.choose_for(chosen["graph"].id, chosen["choice"]):
				return true
	viewer.show_buttons()
	return false
