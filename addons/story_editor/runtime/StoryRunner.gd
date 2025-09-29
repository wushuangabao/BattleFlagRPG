class_name StoryRunner extends AbstractSystem

signal node_entered(node: StoryNode)
signal choice_requested(node: ChoiceNode, options: PackedStringArray)
signal game_ended(ending_id: String)

var graph: StoryGraph
var current: StoryNode
var state := {
	"variables": {},
	"visited": {}
}

func on_init() -> void:
	register_event("battle_end", _on_battle_end)

func _on_battle_end(player_victory: bool) -> void:
	if not current or not current is BattleNode:
		return
	Game.g_scenes.back_to_origin_scene()
	var node = current as BattleNode
	if player_victory:
		_goto(node.get_next_for(node.success))
	else:
		_goto(node.get_next_for(node.fail))

func _init() -> void:
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)

func _ready() -> void:
	Game.g_runner = self
	set_architecture(GameArchitecture.new())
	print("游戏架构初始化完毕")

func _on_timeline_started():
	pass

func _on_timeline_ended():
	if not current or not current is DialogueNode:
		return
	var node = current as DialogueNode
	var port_name = null
	if node.var_name == null or node.var_name.is_empty():
		if node.outputs and node.outputs.keys().size() > 0:
			port_name = node.outputs.keys()[0]
	else:
		var dialog_var = Dialogic.VAR.get_variable(node.var_name)
		if dialog_var is String:
			port_name = dialog_var
	if port_name != null:
		print("StoryRunner: chose port_name = ", port_name)
	else:
		push_error("StoryRunner: DialogueNode %s has no port" % node.name)
		return
	var next_id = node.get_next_for(port_name)
	if next_id != "":
		_goto(next_id)
	else:
		push_error("StoryRunner: DialogueNode %s not find port %s" % [node.name, port_name])

func _goto(node_id: String) -> void:
	var node = graph.get_node_by_id(node_id)
	if node == null:
		push_error("StoryRunner: node not found: %s" % node_id)
		return
	print("StoryRunner: goto %s(%s)" % [node.name, node_id])
	current = node
	# 标记访问
	state.visited[node.id] = true
	# 进入执行效果
	_apply_effects(node.effects)
	emit_signal("node_entered", node)
	var scr = node.get_script().get_global_name() as StringName
	match scr:
		&"DialogueNode":                             # 对话（调用Dialogic插件）
			if Dialogic.current_timeline != null:
				await Dialogic.timeline_ended
			Dialogic.start(node.timeline)
		&"BattleNode":                               # 战斗
			if Game.g_scenes == null:
				print("预览模式，直接胜利。")
				_goto(node.get_next_for(node.success))
			else:
				Game.g_scenes.start_battle(node.battle)
		&"SceneChoiceNode":                           # 选项（场景中卡片，非对话）
			if Game.g_scenes == null:
				_preview_choices(node)
			else:
				var scene_data := node.scene_data as SceneData
				if scene_data != null:
					Game.g_scenes.show_scene(scene_data)
		&"EndingNode":                                # 结局（游戏结束）
			emit_signal("game_ended", node.ending_id)

func _preview_choices(node: ChoiceNode) -> void:
	print("预览模式，直接列出选项：")
	var options := PackedStringArray()
	for chosen in node.choices:
		var enabled := true
		if chosen.condition != null:
			enabled = chosen.condition.evaluate(state)
		if enabled:
			options.append(chosen.text)
		else:
			var txt = chosen.text_diabled if not chosen.text_disabled.is_empty() else "Locked Yet"
			options.append(txt)
	emit_signal("choice_requested", node as ChoiceNode, options)

func _apply_effects(effects: Array) -> void:
	for e in effects:
		if e and e is ChoiceEffect:
			e.apply(state)

func start(p_graph: StoryGraph, entry: String = "") -> void:
	graph = p_graph
	graph.ensure_entry()
	var start_id = entry if entry != "" else graph.entry_node
	_goto(start_id)

func choose(chosen: Choice) -> bool:
	if not (current is ChoiceNode):
		return false
	var node := current as ChoiceNode
	if not node.choices.has(chosen):
		return false
	# 选项效果
	if chosen.effects != null:
		_apply_effects(chosen.effects)
	# 跳转
	var port_name := chosen.port
	var target := node.get_next_for(port_name)
	if target != "":
		_goto(target)
		return true
	return false
