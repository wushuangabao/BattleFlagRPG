@tool
extends Window

@export var graph_edit: GraphEdit

@export var btn_new: Button
@export var btn_load: Button
@export var btn_save: Button
@export var btn_save_as: Button
@export var btn_set_entry: Button
@export var btn_add_menu: MenuButton
@export var btn_delete: Button
@export var btn_undo: Button
@export var btn_play: Button

var inspector : EditorInspector

var graph_res: StoryGraph = null
var node_map : Dictionary[String, GraphNode] = {} # id -> GraphNode
var aux: GraphDockAux = null

var edited_story_node: StoryNode = null
var _choice_change_connected: Array = []

func _ready():
	if not Engine.is_editor_hint():
		return
	inspector = null
	_try_set_inspector()
	if aux == null or not aux is GraphDockAux:
		aux = GraphDockAux.new(self, graph_edit)

	btn_new.pressed.connect(_on_new)
	btn_load.pressed.connect(_on_load)
	btn_save.pressed.connect(_on_save)
	btn_save_as.pressed.connect(_on_save_as)
	btn_set_entry.pressed.connect(_on_set_entry_pressed)

	var popup := btn_add_menu.get_popup()
	popup.index_pressed.connect(_on_add_menu_index_pressed)
	
	btn_delete.pressed.connect(aux._on_delete_pressed)
	btn_undo.pressed.connect(aux._on_undo_pressed)
	btn_play.pressed.connect(aux._on_preview)
	
	graph_edit.connection_request.connect(_on_connect_request)
	graph_edit.disconnection_request.connect(_on_disconnect_request)
	graph_edit.node_selected.connect(_on_node_selected)

	graph_res = load("res://addons/story_editor/demo/story_test.tres")
	_rebuild_from_resource()

	self.gui_embed_subwindows = false
	self.exclusive = true
	set_process_input(true)
	get_viewport().gui_embed_subwindows = false
	set_process_unhandled_input(true)
	self.get_viewport().files_dropped.connect(aux._on_files_dropped)

func _try_set_inspector():
	if inspector != null:
		return
	var inspector_parent = get_node("VBoxContainer/HSplitContainer/Inspector")
	if inspector_parent and inspector_parent.get_child_count() > 0:
		inspector = inspector_parent.get_child(0)
		inspector.property_edited.connect(_on_node_changed)

func _on_files_dropped(files):
	if files.size() > 0:
		var file_path = files[0]
		if file_path.get_extension() in ["tres", "res"]:
			# 检查资源类型是否为StoryGraph
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var first_line = file.get_line()
				file.close()
				if "script_class=\"StoryGraph\"" in first_line:
					print("加载拖入的 StoryGraph：", file_path)
					_load_story_graph(file_path)
				else:
					push_warning("拖放的文件不是StoryGraph类型：" + file_path)
			else:
				push_warning("无法打开文件：" + file_path)

func _on_new():
	graph_res = StoryGraph.new()
	graph_res.id = "graph_%s" % str(Time.get_ticks_msec())
	graph_res.title = "新剧情图"
	graph_res.entry_node = ""
	node_map.clear()
	graph_edit.clear_connections()
	for c in graph_edit.get_children():
		if c is GraphNode:
			c.free()

func _on_load():
	var dlg := FileDialog.new()
	dlg.access = FileDialog.ACCESS_RESOURCES
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dlg.add_filter("*.tres,*.res ; StoryGraph")
	add_child(dlg)
	dlg.file_selected.connect(func(path):
		_load_story_graph(path)
		dlg.queue_free()
	)
	dlg.canceled.connect(dlg.queue_free)
	dlg.popup_centered()
	
func _load_story_graph(path: String):
	graph_res = load(path)
	for n in graph_res.nodes:
		n.outputs = n.outputs.duplicate()
	_rebuild_from_resource()

func _on_save():
	if graph_res == null:
		return
	# 同步 GraphNode 到资源
	_sync_to_resource()
	# 直接覆盖保存到原路径；若资源尚未有路径，则转为另存为
	var path := graph_res.resource_path
	if path.is_empty():
		_on_save_as()
		return
	ResourceSaver.save(graph_res, path)
	print("已保存到：", path)

func _on_save_as():
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
		print("已另存为：", path)
		dlg.queue_free()
	)
	dlg.canceled.connect(dlg.queue_free)
	dlg.popup_centered()

func _add_node_ui(cls):
	if graph_res == null:
		_on_new()
	var n: StoryNode = cls.new()
	n.id = _gen_id()
	var gn := _create_graph_node(n, true)
	n.position = gn.position_offset
	graph_res.nodes.append(n)
	if n is ChoiceNode and graph_res.entry_node == "":
		graph_res.entry_node = n.id
		gn.set_slot_color_left(0, Color.RED)

func _gen_id() -> String:
	var id := "n_%x" % randi()
	# 确保生成的ID不会与node_map中已存在的ID冲突
	while node_map.has(id):
		id = "n_%x" % randi()
	return id

func _on_connect_request(from_node, from_port, to_node, to_port):
	var from_res := _find_res_node(from_node)
	var to_res := _find_res_node(to_node)
	if from_res == null or to_res == null:
		push_warning("连接失败：节点不存在")
		return
	if from_res is EndingNode:
		push_warning("连接失败：EndingNode不能连接到其他节点")
		return
	var port_name = to_res.name
	if port_name == null or port_name.is_empty():
		push_warning("连接失败：目标节点名称为空")
		return
	if from_res is DialogueNode and (from_res.var_name == null or from_res.var_name.is_empty()):
		if from_res.outputs.size() > 0:
			# 若已存在连接，则断开旧连接并清理映射，然后继续建立新连接
			var conns = graph_edit.get_connection_list()
			for c in conns.duplicate():
				if c.from_node == from_node and c.from_port == 0:
					graph_edit.disconnect_node(c.from_node, c.from_port, c.to_node, c.to_port)
			for k in from_res.outputs.keys():
				from_res.outputs.erase(k)
	elif from_res is BattleNode:
		# 若该端口已有连接，则先断开旧连接并移除映射，再接入新连接
		if from_port == 0 and not from_res.success.is_empty():
			var old_port_name: String = from_res.success
			if from_res.outputs.has(old_port_name):
				var old_target_id: String = from_res.outputs[old_port_name]
				if not old_target_id.is_empty():
					graph_edit.disconnect_node(from_node, from_port, old_target_id, 0)
				from_res.outputs.erase(old_port_name)
		elif from_port == 1 and not from_res.fail.is_empty():
			var old_port_name: String = from_res.fail
			if from_res.outputs.has(old_port_name):
				var old_target_id: String = from_res.outputs[old_port_name]
				if not old_target_id.is_empty():
					graph_edit.disconnect_node(from_node, from_port, old_target_id, 0)
				from_res.outputs.erase(old_port_name)
		if from_port == 0:
			from_res.success = port_name
		elif from_port == 1:
			from_res.fail = port_name
		# 更新 BattleNode 对应 GraphNode 上的 Label 文本
		var gn_battle: GraphNode = node_map.get(from_res.id, null)
		if gn_battle:
			for child in gn_battle.get_children():
				if child is Label:
					var idx := child.get_index()
					if idx == 1:
						child.text = from_res.success
					elif idx == 2:
						child.text = from_res.fail
	elif from_res is ChoiceNode:
		if not from_res.choices[from_port].port.is_empty():
			# 端口已连接：先断开旧连接并移除映射，再接入新连接
			var old_port_name: String = from_res.choices[from_port].port
			if from_res.outputs.has(old_port_name):
				var old_target_id: String = from_res.outputs[old_port_name]
				if not old_target_id.is_empty():
					graph_edit.disconnect_node(from_node, from_port, old_target_id, 0)
				from_res.outputs.erase(old_port_name)
		from_res.choices[from_port].port = port_name
	from_res.outputs[port_name as String] = to_res.id
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_disconnect_request(from_node, from_port, to_node, to_port):
	var from_res := _find_res_node(from_node)
	if from_res == null:
		return
	var keys = from_res.outputs.keys()
	for k in keys:
		if from_res.outputs[k] == to_node:
			from_res.outputs.erase(k)
	if from_res is ChoiceNode:
		from_res.choices[from_port].port = ""
	elif from_res is BattleNode:
		if from_port == 0:
			from_res.success = ""
		elif from_port == 1:
			from_res.fail = ""
		# 清空对应 GraphNode 上的 Label 文本以同步 UI
		var gn_battle: GraphNode = node_map.get(from_res.id, null)
		if gn_battle:
			for child in gn_battle.get_children():
				if child is Label:
					var idx := child.get_index()
					if idx == 1:
						child.text = from_res.success
					elif idx == 2:
						child.text = from_res.fail
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func _find_res_node(p_id: String) -> Resource:
	for n in graph_res.nodes:
		if n.id == p_id:
			return n
	return null

func _find_res_node_by_name(p_name: String) -> Resource:
	for n in graph_res.nodes:
		if n.name == p_name:
			return n
	return null

func _rebuild_from_resource():
	if graph_res == null:
		return
	# 清空
	node_map.clear()
	graph_edit.clear_connections()
	for c in graph_edit.get_children():
		if c is GraphNode:
			c.free()
	# 等待所有节点完全移除
	var tree = get_tree()
	if tree != null:
		await tree.process_frame
	# 构建
	for n in graph_res.nodes:
		var gn := _create_graph_node(n)
	# 等待所有节点完全创建
	if tree != null:
		await tree.process_frame
	# 连接
	for n in graph_res.nodes:
		if n is BattleNode:
			if n.success and not n.success.is_empty() and n.outputs.has(n.success):
				var target_id: String = n.outputs[n.success]
				if node_map.has(target_id):
					graph_edit.connect_node(n.id, 0, target_id, 0)
			if n.fail and not n.fail.is_empty() and n.outputs.has(n.fail):
				var target_id: String = n.outputs[n.fail]
				if node_map.has(target_id):
					graph_edit.connect_node(n.id, 1, target_id, 0)
		elif n is ChoiceNode:
			for i in range(n.choices.size()):
				if not n.choices[i].port.is_empty() and n.outputs.has(n.choices[i].port):
					var target_id: String = n.outputs[n.choices[i].port]
					if node_map.has(target_id):
						graph_edit.connect_node(n.id, i, target_id, 0)
		else:
			for k in n.outputs.keys():
				var target_id: String = n.outputs[k]
				if not target_id.is_empty() and node_map.has(n.id) and node_map.has(target_id):
					graph_edit.connect_node(n.id, 0, target_id, 0)

func _create_graph_node(n: StoryNode, is_new: bool = false) -> GraphNode:
	var gn := GraphNode.new()
	gn.title = n.get_script().get_global_name()
	gn.name = n.id
	gn.size.x = 150
	if is_new:
		gn.position_offset = graph_edit.scroll_offset / graph_edit.zoom + Vector2(100, 100)
	else:
		gn.position_offset = n.position
	gn.resizable = true
	gn.draggable = true
	var lbl = LineEdit.new()
	lbl.placeholder_text = "name"
	if not is_new:
		lbl.text = n.name
	lbl.text_submitted.connect(func(t): 
		n.name = t
		_update_references_on_name_change(n.id, t)
		if edited_story_node == n:
			_on_save()
	)
	gn.add_child(lbl)
	gn.clear_all_slots()
	match gn.title:
		&"DialogueNode":
			_set_dialogue_node(gn, n, is_new)
		&"BattleNode":
			_set_battle_node(gn, n, is_new)
		&"MapChoiceNode":
			_set_choice_node(gn, n, is_new)
		&"SceneChoiceNode":
			_set_choice_node(gn, n, is_new)
		&"EndingNode":
			_set_ending_node(gn, n, is_new)
	if graph_res.entry_node == n.id:
		gn.set_slot_color_left(0, Color.RED)
	graph_edit.add_child(gn)
	node_map[n.id] = gn
	return gn

func _set_dialogue_node(gn: GraphNode, n: DialogueNode, is_new: bool = false):
	if is_new == false:
		if n.var_name and not n.var_name.is_empty():
			# 检查变量是否存在 project.godot / ProjectSettings 中
			if not _project_variable_exists(n.var_name):
				push_warning("变量不存在于 ProjectSettings: %s" % n.var_name)
	else:
		n.var_name = ""
	gn.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

func _set_battle_node(gn: GraphNode, n: BattleNode, is_new: bool = false):
	var success = Label.new()
	success.text = ""
	if not is_new:
		success.text = n.success
	gn.add_child(success)
	var fail = Label.new()
	fail.text = ""
	if not is_new:
		fail.text = n.fail
	gn.add_child(fail)
	gn.set_slot(0, true, 0, Color.YELLOW, false, 0, Color.YELLOW)
	gn.set_slot(1, false, 0, Color.YELLOW, true, 0, Color.YELLOW)
	gn.set_slot(2, false, 0, Color.YELLOW, true, 0, Color.YELLOW)

func _set_choice_node(gn: GraphNode, n: ChoiceNode, is_new: bool = false):
	gn.set_slot(0, true, 0, Color.GREEN, false, 0, Color.GREEN)
	for i in range(n.choices.size()):
		var choice = n.choices[i]
		var choice_txt = Label.new()
		if not is_new and choice.text:
			choice_txt.text = choice.text
		gn.add_child(choice_txt)
		gn.set_slot(i + 1, false, 0, Color.GREEN, true, 0, Color.GREEN)

func _set_ending_node(gn: GraphNode, n: EndingNode, is_new: bool = false):
	var ending_id = LineEdit.new()
	ending_id.placeholder_text = "ending_id"
	if not is_new:
		ending_id.text = n.ending_id
	ending_id.text_submitted.connect(func(t):
		n.ending_id = t
		if edited_story_node == n:
			_on_save()
	)
	gn.add_child(ending_id)
	gn.set_slot(0, true, 0, Color.RED, false, 0, Color.WHITE)

func _sync_to_resource():
	# 保存位置
	for n in graph_res.nodes:
		var gn: GraphNode = node_map.get(n.id, null)
		if gn:
			n.position = gn.position_offset

# 查找所有指向该节点的前置节点，并更新它们的outputs字典
func _update_references_on_name_change(node_id: String, new_name: String):
	if graph_res == null:
		return		
	for source_node in graph_res.nodes:
		if source_node is BattleNode:
			if not source_node.success.is_empty() and source_node.outputs.has(source_node.success) and source_node.outputs[source_node.success] == node_id:
				source_node.outputs.erase(source_node.success)
				source_node.success = new_name
				source_node.outputs[new_name] = node_id
				continue
			if not source_node.fail.is_empty() and source_node.outputs.has(source_node.fail) and source_node.outputs[source_node.fail] == node_id:
				source_node.outputs.erase(source_node.fail)
				source_node.fail = new_name
				source_node.outputs[new_name] = node_id
				continue
		elif source_node is ChoiceNode:
			for i in range(source_node.choices.size()):
				var choice = source_node.choices[i]
				if not choice.port.is_empty() and source_node.outputs.has(choice.port) and source_node.outputs[choice.port] == node_id:
					source_node.outputs.erase(choice.port)
					choice.port = new_name
					source_node.outputs[new_name] = node_id
					continue
		var keys_to_update = []
		for port_name in source_node.outputs.keys():
			# 如果输出指向目标节点
			if source_node.outputs[port_name] == node_id:
				keys_to_update.append(port_name)
		# 更新找到的键
		for old_key in keys_to_update:
			source_node.outputs.erase(old_key)
			source_node.outputs[new_name] = node_id

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		_show_delete_confirmation()

func _show_delete_confirmation():
	aux._show_delete_confirmation()
	
func _on_node_selected(node: GraphNode):
	var node_res = _find_res_node(node.name)
	if node_res:
		_sync_to_resource()
		if inspector:
			inspector.edit(node_res)
		else:
			_try_set_inspector()
		EditorInterface.get_inspector().edit(node_res)
		edited_story_node = node_res
		if node_res is ChoiceNode:
			_connect_resource_change_signals(node_res)

func _on_set_entry_pressed():
	if graph_res == null:
		return
	# 查找选中的节点
	var selected_nodes = []
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			selected_nodes.append(child)
	# 如果只有一个节点被选中，将其设置为入口节点
	if selected_nodes.size() == 1:
		var node = _find_res_node(selected_nodes[0].name)
		if node == null:
			push_error("找不到被选为入口的 StoryNode！")
			return
		if not node is ChoiceNode:
			push_warning("只能设置 ChoiceNode 为入口")
			return
		if graph_res.entry_node != node.id:
			if node_map.has(graph_res.entry_node):
				var old_entry_node = node_map[graph_res.entry_node]
				if old_entry_node:
					old_entry_node.set_slot_color_left(0, Color.GREEN)
			graph_res.entry_node = node.id
			selected_nodes[0].set_slot_color_left(0, Color.RED)
			print("设置入口节点为：%s(%s)" % [node.name, node.id])

func _on_node_changed(property: String) -> void:
	if graph_res == null:
		return
	if inspector == null:
		return
	var edited = inspector.get_edited_object()
	if edited is StoryNode:
		_update_graph_node_for_resource(edited, property)
		# 重新绑定资源变更信号，确保 choices 子资源的变更也能触发 UI 更新
		if edited is ChoiceNode:
			_connect_resource_change_signals(edited)

# 监听被编辑资源及其子 Choice 资源的 changed 信号，以捕获容器内元素的变更
func _connect_resource_change_signals(res: ChoiceNode) -> void:
	if res == null:
		return
	_disconnect_resource_change_signals()
	_choice_change_connected.clear()
	edited_story_node = res
	for ch in res.choices:
		if ch != null and not ch.is_connected("changed", _on_resource_changed):
			print("_connect_resource_change_signals node %s" % ch.text)
			ch.changed.connect(_on_resource_changed)
			_choice_change_connected.append(ch)

func _disconnect_resource_change_signals() -> void:
	for ch in _choice_change_connected:
		if ch != null and ch.is_connected("changed", _on_resource_changed):
			ch.changed.disconnect(_on_resource_changed)
	_choice_change_connected.clear()
	edited_story_node = null

func _on_resource_changed() -> void:
	if edited_story_node != null:
		print("_on_resource_changed node %s(%s)" % [edited_story_node.name, edited_story_node.id])
		_update_graph_node_for_resource(edited_story_node, "")
		# choices 数组可能发生了增删，刷新子资源信号绑定
		_connect_resource_change_signals(edited_story_node)

# 仅更新发生改变的 StoryNode 对应的 GraphNode
func _update_graph_node_for_resource(n: StoryNode, property: String) -> void:
	var gn: GraphNode = node_map.get(n.id, null)
	if gn == null:
		push_error("update_graph_node: 找不到对应的 GraphNode 节点！")
		return
	# 更新文本字段
	for child in gn.get_children():
		if child is LineEdit:  # 如果后续新增字段，请确保对应 LineEdit 的 placeholder_text 与资源属性保持一致
			match child.placeholder_text:
				"name":
					if child.text != n.name:
						child.text = n.name
				"ending_id":
					if n is EndingNode:
						child.text = (n as EndingNode).ending_id
		elif child is Label:
			if n is BattleNode:
				var idx = child.get_index()
				if idx == 1:  # success标签
					child.text = (n as BattleNode).success
				elif idx == 2:  # fail标签
					child.text = (n as BattleNode).fail
			elif n is ChoiceNode:
				var idx = child.get_index() - 1
				if idx >= 0 and idx < n.choices.size():
					var ch := (n as ChoiceNode).choices[idx]
					var txt := ""
					if ch != null:
						txt = ch.text
					child.text = txt
	# ChoiceNode 端口与子控件增删同步，保持与 _set_choice_node 一致
	if n is ChoiceNode:
		var choice_children: Array = []
		for cc in gn.get_children():
			if cc is Label:
				choice_children.append(cc)
		var old_count := choice_children.size()
		var new_choices := (n as ChoiceNode).choices
		var new_count := 0
		for ch in new_choices:
			if ch != null:
				new_count += 1
		if new_count != old_count:
			# 清掉所有旧的 choice 行，避免索引错位
			for cc in choice_children:
				if cc:
					cc.free()
			# 按 n.choices 顺序完整重建并绑定
			for i in range(new_count):
				var ch := (n as ChoiceNode).choices[i]
				var choice_txt := Label.new()
				choice_txt.text = ch.text
				gn.add_child(choice_txt)
			# 重建槽位，使端口定义与 _set_choice_node 一致
			gn.clear_all_slots()
			gn.set_slot(0, true, 0, Color.GREEN, false, 0, Color.GREEN)
			for i in range(new_count):
				gn.set_slot(i + 1, false, 0, Color.GREEN, true, 0, Color.GREEN)
			# 如果该节点是入口节点，恢复左侧红色标记
			if graph_res.entry_node == n.id:
				gn.set_slot_color_left(0, Color.RED)
			# 按需重连：仅断开并重连本节点的所有输出
			var conns = graph_edit.get_connection_list()
			for c in conns.duplicate():
				if c.from_node == n.id:
					graph_edit.disconnect_node(c.from_node, c.from_port, c.to_node, c.to_port)
			for i in range(new_count):
				var ch2 := (n as ChoiceNode).choices[i]
				var port_name := ""
				if ch2 != null:
					port_name = ch2.port
				if not port_name.is_empty() and n.outputs.has(port_name):
					var target_id: String = n.outputs[port_name]
					if not target_id.is_empty() and node_map.has(n.id) and node_map.has(target_id):
						graph_edit.connect_node(n.id, i, target_id, 0)
		elif new_count == old_count:
			# 检测顺序变化（不重建控件），仅按新索引重连
			var expected: Dictionary = {}
			for i in range(new_count):
				var ch3 := (n as ChoiceNode).choices[i]
				var port_name := ""
				if ch3 != null:
					port_name = ch3.port
				var target_id := ""
				if not port_name.is_empty() and n.outputs.has(port_name):
					target_id = n.outputs[port_name]
				expected[i] = target_id
			var actual: Dictionary = {}
			var conns = graph_edit.get_connection_list()
			for c in conns:
				if c.from_node == n.id:
					actual[c.from_port] = c.to_node
			var order_mismatch := false
			for i in range(new_count):
				var e := expected.get(i, "")
				var a := actual.get(i, "")
				if e != a:
					order_mismatch = true
					break
			if order_mismatch:
				# 断开本节点所有外向连接
				for c in conns.duplicate():
					if c.from_node == n.id:
						graph_edit.disconnect_node(c.from_node, c.from_port, c.to_node, c.to_port)
				# 按新索引重连
				for i in range(new_count):
					var target_id := expected.get(i, "")
					if not target_id.is_empty() and node_map.has(n.id) and node_map.has(target_id):
						graph_edit.connect_node(n.id, i, target_id, 0)

# 检查 ProjectSettings 中是否存在给定的变量路径（如 "Folder.Var_test" 或更深层级如 "Folder.Sub.Var"）
func _project_variable_exists(var_path: String) -> bool:
	if var_path == null:
		return false
	var_path = var_path.strip_edges()
	if var_path.is_empty():
		return false
	var settings_key := "dialogic/variables"
	if not ProjectSettings.has_setting(settings_key):
		return false
	var vars_root := ProjectSettings.get_setting(settings_key)
	if vars_root == null:
		return false
	# 仅支持字典结构
	if vars_root is Dictionary:
		var dict: Dictionary = vars_root
		var parts := var_path.split(".")
		if parts.size() == 1:
			var key := parts[0]
			if dict.has(key):
				return true
			return false
		# 多层路径：逐层深入，最后检查叶子键是否存在
		var current: Variant = dict
		for i in range(parts.size() - 1):
			var seg := parts[i]
			if current is Dictionary and (current as Dictionary).has(seg):
				current = (current as Dictionary)[seg]
			else:
				return false
		# 检查叶子键
		if current is Dictionary:
			return (current as Dictionary).has(parts[parts.size() - 1])
	return false

func _on_add_menu_index_pressed(index: int) -> void:
	match index:
		0:
			_add_node_ui(DialogueNode)
		1:
			_add_node_ui(BattleNode)
		2:
			_add_node_ui(MapChoiceNode)
		3:
			_add_node_ui(SceneChoiceNode)
		4:
			_add_node_ui(EndingNode)
		_:
			pass
