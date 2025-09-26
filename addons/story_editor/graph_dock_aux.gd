class_name GraphDockAux
extends RefCounted

var owner: Window
var graph_edit: GraphEdit
var undo_stack := []

func _init(owner_window: Window, graph_edit_node: GraphEdit) -> void:
	owner = owner_window
	graph_edit = graph_edit_node

func _on_files_dropped(files):
	if files.size() > 0:
		var file_path = files[0]
		if file_path.get_extension() in ["tres", "res"]:
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var first_line = file.get_line()
				file.close()
				if "script_class=\"StoryGraph\"" in first_line:
					print("加载拖入的 StoryGraph：", file_path)
					owner._load_story_graph(file_path)
				else:
					owner.push_warning("拖放的文件不是StoryGraph类型：" + file_path)
			else:
				owner.push_warning("无法打开文件：" + file_path)

func _on_preview():
	if owner.graph_res == null:
		return
	owner._sync_to_resource()
	if DialogicUtil and DialogicUtil.get_dialogic_plugin():
		owner.hide()
		ResourceSaver.save(owner.graph_res, "res://addons/story_editor/demo/story_test.tres")
		EditorInterface.play_custom_scene("res://addons/story_editor/demo/main.tscn")
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.autostart = true
		owner.add_child(timer)
		timer.timeout.connect(func():
			if not EditorInterface.is_playing_scene():
				owner.show()
				timer.queue_free()
		)

func _show_delete_confirmation():
	var has_selected = false
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			has_selected = true
			break
	if not has_selected:
		return
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认删除"
	dialog.dialog_text = "确定要删除选中的节点吗？"
	dialog.get_ok_button().text = "确定"
	dialog.get_cancel_button().text = "取消"
	dialog.min_size = Vector2(300, 100)
	owner.add_child(dialog)
	dialog.confirmed.connect(func():
		_delete_selected_nodes()
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	dialog.popup_centered()

func _on_delete_pressed():
	_show_delete_confirmation()

func _delete_selected_nodes():
	if owner.graph_res == null:
		return
	var selected_nodes = []
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			selected_nodes.append(child)
	if selected_nodes.size() == 0:
		return
	var undo_record = {
		"nodes": [],
		"connections": []
	}
	for node in selected_nodes:
		if owner.graph_res.entry_node == owner._find_res_node(node.name).id:
			owner.push_warning("不能删除入口节点！")
			continue
		var node_record = {
			"node_id": node.name,
			"position": node.position_offset,
			"resource": null,
			"connections": []
		}
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
		var res_node = owner._find_res_node(node.name)
		if res_node != null:
			node_record.resource = res_node.duplicate(true)
			owner.graph_res.nodes.erase(res_node)
			for n in owner.graph_res.nodes:
				var keys_to_erase = []
				for k in n.outputs.keys():
					if n.outputs[k] == node.name:
						keys_to_erase.append(k)
						node_record.connections.append({
							"ref_node": n.id,
							"ref_key": k,
							"ref_value": node.name
						})
				for k in keys_to_erase:
					n.outputs.erase(k)
		owner.node_map.erase(node.name)
		node.queue_free()
		undo_record.nodes.append(node_record)
	undo_stack.append(undo_record)

func _on_undo_pressed():
	if undo_stack.size() == 0:
		return
	var undo_record = undo_stack.pop_back()
	for node_record in undo_record.nodes:
		if node_record.resource != null:
			owner.graph_res.nodes.append(node_record.resource)
			var gn = owner._create_graph_node(node_record.resource)
			for conn in node_record.connections:
				if conn.has("from"):
					if owner.node_map.has(conn.from) and owner.node_map.has(conn.to):
						graph_edit.connect_node(conn.from, conn.from_port, conn.to, conn.to_port)
						var from_res = owner._find_res_node(conn.from)
						if from_res != null:
							from_res.outputs["out"] = conn.to
				elif conn.has("ref_node"):
					var ref_node = owner._find_res_node(conn.ref_node)
					if ref_node != null:
						ref_node.outputs[conn.ref_key] = conn.ref_value