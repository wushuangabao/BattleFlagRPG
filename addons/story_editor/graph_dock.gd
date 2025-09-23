@tool
extends VBoxContainer

@export var graph_edit: GraphEdit
@export var btn_new: Button
@export var btn_load: Button
@export var btn_save: Button
@export var btn_add_dlg: Button
@export var btn_add_choice: Button
@export var btn_add_end: Button
@export var btn_play: Button

var graph_res: Resource = null
var node_map := {} # id -> GraphNode

func _ready():
	if not Engine.is_editor_hint():
		return
	btn_new.pressed.connect(_on_new)
	btn_load.pressed.connect(_on_load)
	btn_save.pressed.connect(_on_save)
	btn_add_dlg.pressed.connect(func(): _add_node_ui(DialogueNode))
	btn_add_choice.pressed.connect(func(): _add_node_ui(ChoiceNode))
	btn_add_end.pressed.connect(func(): _add_node_ui(EndingNode))
	graph_edit.connection_request.connect(_on_connect_request)
	graph_edit.disconnection_request.connect(_on_disconnect_request)
	btn_play.pressed.connect(_on_preview)

func _on_new():
	graph_res = StoryGraph.new()
	graph_res.id = "graph_%s" % str(Time.get_ticks_msec())
	graph_res.title = "新剧情图"
	graph_res.entry_node = ""
	node_map.clear()
	graph_edit.clear_connections()
	for c in graph_edit.get_children():
		if c is GraphNode:
			c.queue_free()

func _on_load():
	var dlg := FileDialog.new()
	dlg.access = FileDialog.ACCESS_RESOURCES
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dlg.add_filter("*.tres,*.res ; StoryGraph")
	add_child(dlg)
	dlg.file_selected.connect(func(path):
		graph_res = load(path)
		_rebuild_from_resource()
		dlg.queue_free()
	)
	dlg.canceled.connect(dlg.queue_free)
	dlg.popup_centered()

func _on_save():
	if graph_res == null:
		return
	# 同步 GraphNode 到资源
	_sync_to_resource()
	var dlg := FileDialog.new()
	dlg.access = FileDialog.ACCESS_RESOURCES
	dlg.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dlg.add_filter("*.tres ; StoryGraph")
	add_child(dlg)
	dlg.file_selected.connect(func(path):
		ResourceSaver.save(graph_res, path)
		dlg.queue_free()
	)
	dlg.canceled.connect(dlg.queue_free)
	dlg.popup_centered()

func _add_node_ui(cls):
	if graph_res == null:
		_on_new()
	var gn := GraphNode.new()
	gn.title = cls.get_class()
	gn.position_offset = graph_edit.scroll_offset + Vector2(40, 40)
	gn.resizable = true
	gn.draggable = true
	# 生成资源节点
	var n: Resource = cls.new()
	n.id = _gen_id()
	n.name = gn.title
	n.position = gn.position_offset
	if n is DialogueNode:
		var speaker = LineEdit.new()
		speaker.placeholder_text = "speaker"
		var line = LineEdit.new()
		line.placeholder_text = "line"
		gn.add_child(speaker)
		gn.add_child(line)
		gn.set_slot(0, true, 0, Color.BLUE, true, 0, Color.WHITE)
		gn.set_slot(1, false, 0, Color.BLUE, true, 0, Color.WHITE) # out
	elif n is ChoiceNode:
		var lbl = Label.new()
		lbl.text = "Choices ports: A,B,C..."
		gn.add_child(lbl)
		gn.set_slot(0, true, 0, Color.BLUE, true, 0, Color.WHITE)
		# 预置三个出口端口
		for i in range(1, 4):
			gn.set_slot(i, false, 0, Color.BLUE, true, 0, Color.WHITE)
	elif n is EndingNode:
		var lbl2 = Label.new()
		lbl2.text = "Ending"
		gn.add_child(lbl2)
		gn.set_slot(0, true, 0, Color.BLUE, false, 0, Color.WHITE)
	gn.name = n.id
	graph_edit.add_child(gn)
	node_map[n.id] = gn
	graph_res.nodes.append(n)
	if graph_res.entry_node == "":
		graph_res.entry_node = n.id

func _gen_id() -> String:
	return "n_%x" % randi()

func _on_connect_request(from_node, from_port, to_node, to_port):
	var from_res := _find_res_node(from_node)
	var to_res := _find_res_node(to_node)
	if from_res == null or to_res == null:
		return
	# 出口名：默认 "out"，对于 ChoiceNode 端口 1->"A",2->"B",3->"C"...
	var port_name := "out"
	if from_res is ChoiceNode and from_port > 0:
		port_name = String.chr(int("A".unicode_at(0)) + from_port - 1)
	from_res.outputs[port_name] = to_res.id
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_disconnect_request(from_node, from_port, to_node, to_port):
	var from_res := _find_res_node(from_node)
	if from_res == null:
		return
	var keys = from_res.outputs.keys()
	for k in keys:
		if from_res.outputs[k] == to_node:
			from_res.outputs.erase(k)
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func _find_res_node(name: String) -> Resource:
	for n in graph_res.nodes:
		if n.id == name:
			return n
	return null

func _rebuild_from_resource():
	# 清空
	node_map.clear()
	graph_edit.clear_connections()
	for c in graph_edit.get_children():
		if c is GraphNode:
			c.queue_free()
	# 构建
	for n in graph_res.nodes:
		var gn := GraphNode.new()
		gn.title = n.get_class()
		gn.name = n.id
		gn.position_offset = n.position
		gn.resizable = true
		gn.draggable = true
		if n is DialogueNode:
			print("build DialogueNode ", n.id)
			var timeline = LineEdit.new()
			timeline.placeholder_text = "timeline"
			timeline.text = n.timeline
			timeline.text_changed.connect(func(t): n.timeline = t)
			var var_name = LineEdit.new()
			var_name.placeholder_text = "var_name"
			var_name.text = n.var_name
			var_name.text_changed.connect(func(t): n.var_name = t)
			gn.add_child(timeline)
			gn.add_child(var_name)
			gn.set_slot(0, true, 0, Color.BLUE, true, 0, Color.WHITE)
			gn.set_slot(1, false, 0, Color.BLUE, true, 0, Color.WHITE)
		elif n is ChoiceNode:
			var lbl = Label.new()
			lbl.text = "Choices ports: A,B,C..."
			gn.add_child(lbl)
			gn.set_slot(0, true, 0, Color.BLUE, true, 0, Color.WHITE)
			for i in range(1, 4):
				gn.set_slot(i, false, 0, Color.BLUE, true, 0, Color.WHITE)
			# 简化：用 Inspector 编辑 choices 数组
		elif n is EndingNode:
			var lbl2 = Label.new()
			lbl2.text = "Ending"
			gn.add_child(lbl2)
			gn.set_slot(0, true, 0, Color.BLUE, false, 0, Color.WHITE)
		graph_edit.add_child(gn)
		node_map[n.id] = gn
	# 连接
	for n in graph_res.nodes:
		for k in n.outputs.keys():
			var target_id: String = n.outputs[k]
			if node_map.has(n.id) and node_map.has(target_id):
				var from_port := 1
				if n is ChoiceNode:
					# "A"->1, "B"->2, ...
					if k == "out":
						from_port = 1
					else:
						from_port = (k.unicode_at(0) - "A".unicode_at(0)) + 1
				graph_edit.connect_node(n.id, from_port, target_id, 0)

func _sync_to_resource():
	# 保存位置
	for n in graph_res.nodes:
		var gn: GraphNode = node_map.get(n.id, null)
		if gn:
			n.position = gn.position_offset

func _on_preview():
	if graph_res == null:
		return
	_sync_to_resource()
	# 简易预览窗口
	var w := Window.new()
	w.title = "剧情预览"
	w.size = Vector2i(520, 320)
	var runner := StoryRunner.new()
	var vb := VBoxContainer.new()
	var lbl := Label.new()
	var line := RichTextLabel.new()
	var vbox_choices := VBoxContainer.new()
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(lbl)
	vb.add_child(line)
	vb.add_child(vbox_choices)
	w.add_child(vb)
	add_child(w)
	var clear_choices = func():
		for c in vbox_choices.get_children():
			c.queue_free()
	runner.choice_requested.connect(func(node:Resource, opts:PackedStringArray):
		clear_choices.call()
		for i in opts.size():
			var b := Button.new()
			b.text = "%d. %s" % [i+1, opts[i]]
			b.pressed.connect(func():
				runner.choose(i)
			)
			vbox_choices.add_child(b)
	)
	runner.ended.connect(func(eid:String):
		lbl.text = "结局"
		line.text = "结束：" + eid
		clear_choices.call()
	)
	w.close_requested.connect(func():
		w.queue_free()
	)
	w.popup_centered()
	runner.start(graph_res)
