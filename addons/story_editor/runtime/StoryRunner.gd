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
	var port_name = Dialogic.VAR.get_variable(node.var_name) if not node.var_name.is_empty() else null
	if port_name != null:
		print("StoryRunner: chose port_name = ", port_name)
	var next_id = node.get_next_for(port_name) if port_name != null else node.get_next_for("out")
	if next_id != "":
		_goto(next_id)

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
				Game.g_scenes.start_battle(node.battle_name)
		&"ChoiceNode":                               # 选项（场景中卡片，非对话）
			var options := PackedStringArray()
			for c_dict in node.choices:
				var enabled := true
				if c_dict.has("condition") and c_dict["condition"] != null:
					enabled = (c_dict["condition"] as Evaluator).evaluate(state)
				if enabled:
					options.append(String(c_dict.get("text", "")))
				else:
					options.append(String(c_dict.get("text_disabled", "Locked Yet")))
			emit_signal("choice_requested", node as ChoiceNode, options)
		&"EndingNode":                               # 结局（游戏结束）
			emit_signal("game_ended", node.ending_id)
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
	var chosen := node.choices[index]
	# 选项效果
	if chosen.has("effects"):
		_apply_effects(chosen["effects"])
	# 跳转
	var port_name := chosen.port
	var target := node.get_next_for(port_name)
	if target == "":
		target = node.get_next_for("out")
	if target != "":
		_goto(target)
