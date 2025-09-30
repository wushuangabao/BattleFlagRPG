class_name StoryRunner extends AbstractSystem

signal node_entered_for(session_id: String, node: StoryNode)
signal choice_requested_for(session_id: String, node: ChoiceNode, options: PackedStringArray)

var graph_manager: StoryGraphManager = StoryGraphManager.new()
var active_session_id: String = ""

func on_init() -> void:
	register_event("battle_end", _on_battle_end)

func _on_battle_end(player_victory: bool) -> void:
	if active_session_id == "":
		return
	var cur := graph_manager.get_current(active_session_id)
	if not cur or not (cur is BattleNode):
		return
	Game.g_scenes.back_to_origin_scene()
	var node = cur as BattleNode
	if player_victory:
		_goto_on(active_session_id, node.get_next_for(node.success))
	else:
		_goto_on(active_session_id, node.get_next_for(node.fail))

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
	if active_session_id == "":
		return
	var cur := graph_manager.get_current(active_session_id)
	if not cur or not (cur is DialogueNode):
		return
	var node = cur as DialogueNode
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
		_goto_on(active_session_id, next_id)
	else:
		push_error("StoryRunner: DialogueNode %s not find port %s" % [node.name, port_name])

func _goto_on(session_id: String, node_id: String) -> void:
	var g := graph_manager.get_graph(session_id)
	if g == null:
		push_error("StoryRunner: session graph not found: %s" % session_id)
		return
	var node = g.get_node_by_id(node_id)
	if node == null:
		push_error("StoryRunner: node not found: %s" % node_id)
		return
	print("StoryRunner: goto %s(%s) [session=%s]" % [node.name, node_id, session_id])
	graph_manager.set_current(session_id, node)
	# 标记访问
	graph_manager.mark_visited(session_id, node.id)
	# 进入执行效果
	_apply_effects_for(session_id, node.effects)
	emit_signal("node_entered_for", session_id, node)
	# 激活状态规则：
	# - ChoiceNode / EndingNode 视为非激活（active_session_id 置空）
	# - DialogueNode / BattleNode 视为激活（active_session_id = session_id）
	if node is ChoiceNode or node is EndingNode:
		if active_session_id == session_id:
			active_session_id = ""
	elif node is DialogueNode or node is BattleNode:
		active_session_id = session_id
	var scr = node.get_script().get_global_name() as StringName
	match scr:
		&"DialogueNode":                             # 对话（调用Dialogic插件）
			if Dialogic.current_timeline != null:
				await Dialogic.timeline_ended
			Dialogic.start(node.timeline)
		&"BattleNode":                               # 战斗
			if Game.g_scenes == null:
				print("预览模式，直接胜利。")
				_goto_on(session_id, node.get_next_for(node.success))
			else:
				Game.g_scenes.start_battle(node.battle)
		&"ChoiceNode":                               # 选项（场景中卡片，非对话）
			if Game.g_scenes == null:
				_preview_choices_for(session_id, node)
		&"EndingNode":                                # 结局（游戏结束）
			Game.g_event.send_event("story_ended", [session_id, node.ending_id])

func _preview_choices_for(session_id: String, node: ChoiceNode) -> void:
	print("预览模式，直接列出选项：")
	var options := PackedStringArray()
	var st := graph_manager.get_state(session_id)
	for chosen in node.choices:
		var enabled := true
		if chosen.condition != null:
			enabled = chosen.condition.evaluate(st)
		if enabled:
			options.append(chosen.text)
		else:
			var txt = chosen.text_disabled if not chosen.text_disabled.is_empty() else "Locked Yet"
			options.append(txt)
	emit_signal("choice_requested_for", session_id, node as ChoiceNode, options)

func _apply_effects_for(session_id: String, effects: Array) -> void:
	var st := graph_manager.get_state(session_id)
	for e in effects:
		if e and e is ChoiceEffect:
			e.apply(st)

func start(p_graph: StoryGraph, entry: String = "") -> String:
	var sid := graph_manager.create_session(p_graph, entry)
	_set_active_session(sid)
	var start_id = entry if entry != "" else p_graph.entry_node
	_goto_on(sid, start_id)
	return sid

func _set_active_session(session_id: String) -> void:
	if not graph_manager.has_session(session_id):
		push_error("StoryRunner: session not found: %s" % session_id)
		return
	active_session_id = session_id

func choose_for(session_id: String, chosen: Choice) -> bool:
	var node := graph_manager.get_current(session_id)
	if not node or not (node is ChoiceNode):
		return false
	var cnode := node as ChoiceNode
	if not cnode.choices.has(chosen):
		return false
	# 选项效果
	if chosen.effects != null:
		_apply_effects_for(session_id, chosen.effects)
	# 跳转
	var port_name := chosen.port
	var target := cnode.get_next_for(port_name)
	if target != "":
		_goto_on(session_id, target)
		return true
	return false
