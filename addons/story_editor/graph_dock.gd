@tool
extends Window

@export var graph_edit: GraphEdit

@export var btn_new: Button
@export var btn_load: Button
@export var btn_save: Button
@export var btn_set_entry: Button

@export var btn_add_dlg: Button
@export var btn_add_battle: Button
@export var btn_add_choice: Button
@export var btn_add_end: Button

@export var btn_edit: Button
@export var btn_delete: Button
@export var btn_undo: Button
@export var btn_play: Button

var graph_res: StoryGraph = null
var node_map : Dictionary[String, GraphNode] = {} # id -> GraphNode
var undo_stack = [] # 撤销栈，用于存储删除的节点信息

func _ready():
	if not Engine.is_editor_hint():
		return
	btn_new.pressed.connect(_on_new)
	btn_load.pressed.connect(_on_load)
	btn_save.pressed.connect(_on_save)
	btn_set_entry.pressed.connect(_on_set_entry_pressed)

	btn_add_dlg.pressed.connect(func(): _add_node_ui(DialogueNode))
	btn_add_battle.pressed.connect(func(): _add_node_ui(BattleNode))
	btn_add_choice.pressed.connect(func(): _add_node_ui(ChoiceNode))
	btn_add_end.pressed.connect(func(): _add_node_ui(EndingNode))
	
	btn_edit.pressed.connect(_on_edit_pressed)
	btn_delete.pressed.connect(_on_delete_pressed)
	btn_undo.pressed.connect(_on_undo_pressed)
	btn_play.pressed.connect(_on_preview)
	
	graph_edit.connection_request.connect(_on_connect_request)
	graph_edit.disconnection_request.connect(_on_disconnect_request)

	graph_res = load("res://addons/story_editor/demo/story_test.tres")
	_rebuild_from_resource()

	# 设置窗口为可聚焦，以便接收键盘输入
	self.gui_embed_subwindows = false
	self.exclusive = true
	
	# 确保窗口可以接收输入事件
	set_process_input(true)
	
	# 启用拖放功能
	get_viewport().gui_embed_subwindows = false
	set_process_unhandled_input(true)
	self.get_viewport().files_dropped.connect(_on_files_dropped)

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
			c.queue_free()

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
	_rebuild_from_resource()

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
	var n: Resource = cls.new()
	n.id = _gen_id()
	var gn := _create_graph_node(n, true)
	n.position = gn.position_offset
	graph_res.nodes.append(n)
	if n is DialogueNode and graph_res.entry_node == "":
		graph_res.entry_node = n.id
		gn.set_slot_color_right(0, Color.RED)

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
		push_error("连接失败：节点不存在")
		return
	# 出口名：默认 "out"
	var port_name := "out"
	if from_res is DialogueNode and not from_res.var_name.is_empty():
		port_name = to_res.name
	elif from_res is BattleNode:
		port_name = to_res.name
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
	if graph_res == null:
		return
	# 清空
	node_map.clear()
	graph_edit.clear_connections()
	for c in graph_edit.get_children():
		if c is GraphNode:
			c.queue_free()
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
		for k in n.outputs.keys():
			var target_id: String = n.outputs[k]
			if node_map.has(n.id) and node_map.has(target_id):
				graph_edit.connect_node(n.id, 0, target_id, 0)

func _create_graph_node(n: StoryNode, is_new: bool = false) -> GraphNode:
	var gn := GraphNode.new()
	gn.title = n.get_script().get_global_name()
	gn.name = n.id
	gn.size.x = 150
	gn.position_offset = n.position
	gn.resizable = true
	gn.draggable = true
	var lbl = LineEdit.new()
	lbl.placeholder_text = "name"
	if not is_new:
		lbl.text = n.name
	lbl.text_changed.connect(func(t): 
		var old_name = n.name
		n.name = t
		_update_references_on_name_change(n.id, old_name, t)
	)
	gn.add_child(lbl)
	match gn.title:
		&"DialogueNode":
			_set_dialogue_node(gn, n, is_new)
		&"BattleNode":
			_set_battle_node(gn, n, is_new)
		&"ChoiceNode":
			_set_choice_node(gn, n, is_new)
		&"EndingNode":
			_set_ending_node(gn, n, is_new)
	if graph_res.entry_node == n.id:
		gn.set_slot_color_right(0, Color.RED)
	graph_edit.add_child(gn)
	node_map[n.id] = gn
	return gn

func _set_dialogue_node(gn: GraphNode, n: DialogueNode, is_new: bool = false):
	var timeline = LineEdit.new()
	timeline.placeholder_text = "timeline"
	if not is_new:
		timeline.text = n.timeline
	timeline.text_changed.connect(func(t): n.timeline = t)
	var var_name = LineEdit.new()
	var_name.placeholder_text = "var_name"
	if not is_new:
		var_name.text = n.var_name
	var_name.text_changed.connect(func(t): n.var_name = t)
	gn.add_child(timeline)
	gn.add_child(var_name)
	gn.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

func _set_battle_node(gn: GraphNode, n: BattleNode, is_new: bool = false):
	var battle_name = LineEdit.new()
	battle_name.placeholder_text = "battle_name"
	if not is_new:
		battle_name.text = n.battle_name
	battle_name.text_changed.connect(func(t): n.battle_name = t)
	gn.add_child(battle_name)
	var success = LineEdit.new()
	success.placeholder_text = "success"
	if not is_new:
		success.text = n.success
	success.text_changed.connect(func(t): n.success = t)
	gn.add_child(success)
	var fail = LineEdit.new()
	fail.placeholder_text = "fail"
	if not is_new:
		fail.text = n.fail
	fail.text_changed.connect(func(t): n.fail = t)
	gn.add_child(fail)
	gn.set_slot(0, true, 0, Color.YELLOW, true, 0, Color.YELLOW)

func _set_choice_node(gn: GraphNode, n: ChoiceNode, is_new: bool = false):
	gn.set_slot(0, true, 0, Color.BLUE, true, 0, Color.BLUE)
	# 在Inspector中编辑按钮
	var btn_inspect := Button.new()
	btn_inspect.text = "在Inspector中编辑"
	btn_inspect.pressed.connect(func():
		_sync_to_resource()
		EditorInterface.edit_resource(n)
	)
	gn.add_child(btn_inspect)

func _set_ending_node(gn: GraphNode, n: EndingNode, is_new: bool = false):
	var ending_id = LineEdit.new()
	ending_id.placeholder_text = "ending_id"
	if not is_new:
		ending_id.text = n.ending_id
	ending_id.text_changed.connect(func(t): n.ending_id = t)
	gn.add_child(ending_id)
	gn.set_slot(0, true, 0, Color.RED, false, 0, Color.WHITE)

func _sync_to_resource():
	# 保存位置
	for n in graph_res.nodes:
		var gn: GraphNode = node_map.get(n.id, null)
		if gn:
			n.position = gn.position_offset

# 查找所有指向该节点的前置节点，并更新它们的outputs字典
func _update_references_on_name_change(node_id: String, old_name: String, new_name: String):
	if graph_res == null:
		return		
	for source_node in graph_res.nodes:
		var keys_to_update = []
		for port_name in source_node.outputs.keys():
			# 如果输出指向目标节点，并且端口名称与旧名称匹配
			if source_node.outputs[port_name] == node_id and port_name == old_name:
				keys_to_update.append(port_name)
		# 更新找到的键
		for old_key in keys_to_update:
			source_node.outputs.erase(old_key)
			source_node.outputs[new_name] = node_id

func _on_preview():
	if graph_res == null:
		return
	_sync_to_resource()
	if DialogicUtil and DialogicUtil.get_dialogic_plugin():
		hide()
		ResourceSaver.save(graph_res, "res://addons/story_editor/demo/story_test.tres")
		EditorInterface.play_custom_scene("res://addons/story_editor/demo/main.tscn")
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.autostart = true
		add_child(timer)
		timer.timeout.connect(func():
			if not EditorInterface.is_playing_scene():
				show()
				timer.queue_free()
		)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		_show_delete_confirmation()

func _show_delete_confirmation():
	# 检查是否有选中的节点
	var has_selected = false
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			has_selected = true
			break
	if not has_selected:
		return
	# 创建确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认删除"
	dialog.dialog_text = "确定要删除选中的节点吗？"
	dialog.get_ok_button().text = "确定"
	dialog.get_cancel_button().text = "取消"
	dialog.min_size = Vector2(300, 100)
	add_child(dialog)
	# 连接确认信号
	dialog.confirmed.connect(func():
		_delete_selected_nodes()
		dialog.queue_free()
	)
	# 连接取消/关闭信号
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	# 显示对话框
	dialog.popup_centered()
	
func _on_edit_pressed():
	var selected_nodes = []
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			selected_nodes.append(child)
			if selected_nodes.size() > 1:
				return
	if selected_nodes.size() == 0:
		return
	var node_res = _find_res_node(selected_nodes[0].name)
	if node_res:
		_sync_to_resource()
		EditorInterface.edit_resource(node_res)
	
func _delete_selected_nodes():
	if graph_res == null:
		return
	
	# 收集所有选中的节点
	var selected_nodes = []
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			selected_nodes.append(child)
	if selected_nodes.size() == 0:
		return
		
	# 创建撤销记录
	var undo_record = {
		"nodes": [],
		"connections": []
	}
	
	# 删除选中的节点
	for node in selected_nodes:
		# 不能删除入口节点
		if graph_res.entry_node == _find_res_node(node.name).id:
			push_warning("不能删除入口节点！")
			continue
		
		var node_record = {
			"node_id": node.name,
			"position": node.position_offset,
			"resource": null,
			"connections": []
		}
		
		# 记录连接信息
		var connections = graph_edit.get_connection_list()
		for connection in connections:
			if connection.from_node == node.name or connection.to_node == node.name:
				node_record.connections.append({
					"from": connection.from_node,
					"from_port": connection.from_port,
					"to": connection.to_node,
					"to_port": connection.to_port
				})
				graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
		
		# 从资源中删除节点并记录
		var res_node = _find_res_node(node.name)
		if res_node != null:
			# 深度复制资源节点以便撤销
			node_record.resource = res_node.duplicate(true)
			graph_res.nodes.erase(res_node)
			
			# 删除其他节点对该节点的引用
			for n in graph_res.nodes:
				var keys_to_erase = []
				for k in n.outputs.keys():
					if n.outputs[k] == node.name:
						keys_to_erase.append(k)
						# 记录引用关系
						node_record.connections.append({
							"ref_node": n.id,
							"ref_key": k,
							"ref_value": node.name
						})
				for k in keys_to_erase:
					n.outputs.erase(k)
		
		# 从节点映射中删除
		node_map.erase(node.name)
		
		# 从场景中删除节点
		node.queue_free()
		
		# 添加到撤销记录
		undo_record.nodes.append(node_record)
	
	# 将撤销记录添加到撤销栈
	undo_stack.append(undo_record)
	
func _on_delete_pressed():
	_show_delete_confirmation()
	
func _on_undo_pressed():
	if undo_stack.size() == 0:
		return
		
	var undo_record = undo_stack.pop_back()
	
	# 恢复节点
	for node_record in undo_record.nodes:
		if node_record.resource != null:
			# 恢复资源节点
			graph_res.nodes.append(node_record.resource)

			# 创建UI节点
			var gn = _create_graph_node(node_record.resource)
			
			# 恢复连接
			for conn in node_record.connections:
				if conn.has("from"):
					# 恢复图形连接
					if node_map.has(conn.from) and node_map.has(conn.to):
						graph_edit.connect_node(conn.from, conn.from_port, conn.to, conn.to_port)
						# 恢复资源节点的输出连接
						var from_res = _find_res_node(conn.from)
						if from_res != null:
							from_res.outputs["out"] = conn.to
				elif conn.has("ref_node"):
					# 恢复引用关系
					var ref_node = _find_res_node(conn.ref_node)
					if ref_node != null:
						ref_node.outputs[conn.ref_key] = conn.ref_value

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
		if not node is DialogueNode:
			push_warning("只能设置 DialogueNode 为入口")
			return
		if graph_res.entry_node != node.id:
			if node_map.has(graph_res.entry_node):
				var old_entry_node = node_map[graph_res.entry_node]
				if old_entry_node:
					old_entry_node.set_slot_color_right(0, Color.WHITE)
			graph_res.entry_node = node.id
			selected_nodes[0].set_slot_color_right(0, Color.RED)
			print("设置入口节点为：%s(%s)" % [node.name, node.id])
