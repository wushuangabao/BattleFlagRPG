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
var undo_stack = [] # 撤销栈，用于存储删除的节点信息
var aux: GraphDockAux = null

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
			push_warning("连接失败：DialogueNode未设置var_name，因此out端口最多连接1个节点")
			return
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
	lbl.text_changed.connect(func(t): 
		n.name = t
		_update_references_on_name_change(n.id, t)
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
	if is_new == false:
		if n.var_name and not n.var_name.is_empty():
			# 检查变量是否存在 project.godot / ProjectSettings 中
			if not _project_variable_exists(n.var_name):
				push_warning("变量不存在于 ProjectSettings: %s" % n.var_name)
	else:
		n.var_name = ""
	gn.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

func _set_battle_node(gn: GraphNode, n: BattleNode, is_new: bool = false):
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
	gn.set_slot(0, true, 0, Color.GREEN, true, 0, Color.GREEN)

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
func _update_references_on_name_change(node_id: String, new_name: String):
	if graph_res == null:
		return		
	for source_node in graph_res.nodes:
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

func _on_node_changed(property: String) -> void:
	if graph_res == null:
		return
	if inspector == null:
		return
	var edited = inspector.get_edited_object()
	if edited is StoryNode:
		_update_graph_node_for_resource(edited, property)

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
				"success":
					if n is BattleNode:
						child.text = (n as BattleNode).success
				"fail":
					if n is BattleNode:
						child.text = (n as BattleNode).fail
				"ending_id":
					if n is EndingNode:
						child.text = (n as EndingNode).ending_id
	# 如果是名称变更，更新其他节点对该节点的引用键名
	if property == "name":
		_update_references_on_name_change(n.id, n.name)
	# 重新整理与该节点相关的连线
	var conns = graph_edit.get_connection_list()
	for c in conns.duplicate():
		if c.from_node == n.id or c.to_node == n.id:
			graph_edit.disconnect_node(c.from_node, c.from_port, c.to_node, c.to_port)
	# 重新连接该节点的所有输出
	for k in n.outputs.keys():
		var target_id: String = n.outputs[k]
		if not target_id.is_empty() and node_map.has(n.id) and node_map.has(target_id):
			graph_edit.connect_node(n.id, 0, target_id, 0)
	# 重新连接指向该节点的输入
	for src in graph_res.nodes:
		for k in src.outputs.keys():
			if src.outputs[k] == n.id:
				if node_map.has(src.id) and node_map.has(n.id):
					graph_edit.connect_node(src.id, 0, n.id, 0)

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
			_add_node_ui(ChoiceNode)
		3:
			_add_node_ui(EndingNode)
		_:
			pass
