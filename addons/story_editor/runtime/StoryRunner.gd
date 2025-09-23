class_name StoryRunner extends AbstractSystem

signal node_entered(node: Resource)
signal choice_requested(node: Resource, options: PackedStringArray)
signal ended(ending_id: String)

var graph: StoryGraph
var current: StoryNode
var state := {
	"variables": {},
	"visited": {}
}

func _init() -> void:
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)

func _on_timeline_started():
	pass

func _on_timeline_ended():
	if not current or not current is DialogueNode:
		return
	var node = current as DialogueNode
	var port_name = Dialogic.VAR.get_variable(node.var_name) if not node.var_name.is_empty() else null
	print("port_name = ", port_name if port_name is String else "null")
	var next_id = node.get_next_for(port_name) if port_name != null else node.get_next_for("out")
	print("next_id = ", next_id)
	if next_id != "":
		_goto(next_id)

func _goto(node_id: String) -> void:
	var node = graph.get_node_by_id(node_id)
	if node == null:
		push_error("StoryRunner: node not found: %s" % node_id)
		return
	print("StoryRunner: goto node = ", node_id)
	current = node
	# 标记访问
	state.visited[node.id] = true
	# 进入执行效果
	_apply_effects(node.effects)
	emit_signal("node_entered", node)
	var scr = node.get_script().get_global_name() as StringName
	match scr:
		&"DialogueNode":                             # 对话（调用Dialogic插件）
			if Dialogic.current_timeline == null:
				Dialogic.start(node.timeline)
				return
			else:
				await Dialogic.timeline_ended
		&"ChoiceNode":                               # 选项（场景中卡片，非对话）
			var options := PackedStringArray()
			for c_dict in node.choices:
				var enabled := true
				if c_dict.has("condition") and c_dict["condition"] != null:
					enabled = c_dict["condition"].evaluate(state)
				if enabled:
					options.append(String(c_dict.get("text", "")))
				else:
					options.append(String(c_dict.get("text_disabled", "Locked Yet")))
			emit_signal("choice_requested", node, options)
		&"EndingNode":                               # 结局（游戏结束）
			emit_signal("ended", node.ending_id)
		_:                                           # 走默认出口
			var nxt = node.get_next_for("out")
			if nxt != "":
				_goto(nxt)

func _apply_effects(effects: Array) -> void:
	for e in effects:
		if e and e is ChoiceEffect:
			e.apply(state)

func start(p_graph: StoryGraph, entry: String = "") -> void:
	graph = p_graph
	graph.ensure_entry()
	var start_id = entry if entry != "" else graph.entry_node
	_goto(start_id)

func choose(index: int) -> void:
	if not (current is ChoiceNode):
		return
	var node := current as ChoiceNode
	if index < 0 or index >= node.choices.size():
		return
	var chosen = node.choices[index]
	# 选项效果
	if chosen.has("effects"):
		_apply_effects(chosen["effects"])
	# 跳转
	var port_name := String(chosen.get("port", "out"))
	var target := node.get_next_for(port_name)
	if target == "":
		target = node.get_next_for("out")
	if target != "":
		_goto(target)
