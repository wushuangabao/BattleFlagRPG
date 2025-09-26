@tool
extends EditorPlugin

var editor_window
var graph_editor
var inspector : EditorInspector

func _enter_tree():
	# 创建独立窗口
	editor_window = preload("res://addons/story_editor/graph_dock.tscn").instantiate()
	editor_window.title = "故事线编辑器"
	editor_window.min_size = Vector2(400, 300)  # 设置最小窗口大小
	editor_window.exclusive = false  # 非独占模式，允许与其他窗口交互
	editor_window.unresizable = false  # 允许调整大小
	editor_window.close_requested.connect(_on_window_close_requested)
	
	inspector = EditorInspector.new()
	inspector.anchors_preset = Control.PRESET_FULL_RECT
	inspector.anchor_right = 1.0
	inspector.anchor_bottom = 1.0
	inspector.offset_left = 0
	inspector.offset_top = 0
	inspector.offset_right = 0
	inspector.offset_bottom = 0
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	editor_window.hide()
	editor_window.get_node("VBoxContainer/HSplitContainer/Inspector").add_child(inspector)
	
	# 将窗口添加到编辑器界面
	get_editor_interface().get_base_control().add_child(editor_window)
	# 添加到菜单（项目-工具）
	add_tool_menu_item("打开故事线编辑器", _on_open_editor_menu_item_pressed)

	# 注册自定义资源图标
	var icon = load("res://addons/story_editor/icon.svg") # 或者使用您的图标路径
	add_custom_type("StoryGraph", "Resource", preload("res://addons/story_editor/runtime/StoryGraph.gd"), icon)
	add_custom_type("DialogueNode", "Resource", preload("res://addons/story_editor/node/DialogueNode.gd"), icon)
	add_custom_type("ChoiceNode", "Resource", preload("res://addons/story_editor/node/ChoiceNode.gd"), icon)
	add_custom_type("EndingNode", "Resource", preload("res://addons/story_editor/node/EndingNode.gd"), icon)
	
	# 输出日志，表示插件已加载
	print("故事线编辑器插件已加载")

# 菜单项点击事件
func _on_open_editor_menu_item_pressed():
	editor_window.show()
	editor_window.grab_focus()

# 窗口关闭请求事件
func _on_window_close_requested():
	editor_window.hide()  # 隐藏而不是关闭，以便再次打开

func _exit_tree():	
	# 移除菜单项
	remove_tool_menu_item("打开故事线编辑器")
	
	# 释放资源
	if editor_window:
		editor_window.queue_free()
		
	# 移除自定义资源类型
	remove_custom_type("StoryGraph")
	remove_custom_type("DialogueNode")
	remove_custom_type("ChoiceNode")
	remove_custom_type("EndingNode")
	
	# 输出日志，表示插件已卸载
	print("故事线编辑器插件已卸载")
