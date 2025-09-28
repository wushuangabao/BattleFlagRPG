class_name SceneViewer extends Control

var background_rect: TextureRect
var buttons_root: HBoxContainer
var button_nodes: Array[TextureButton]
var back_button_node: TextureButton
var bgm: AudioStreamPlayer
var sfx: AudioStreamPlayer

var current_data: SceneData
var scale_factor := 1.0
var content_size := Vector2(1920, 1080) # 与 SceneData.design_size 对齐

func _ready() -> void:
	background_rect = get_node("Background")
	back_button_node = get_node("BackButton")
	buttons_root = get_node("Buttons")
	button_nodes = [
		get_node("Buttons/TextureButton1"),
		get_node("Buttons/TextureButton2"),
		get_node("Buttons/TextureButton3"),
		get_node("Buttons/TextureButton4"),
		get_node("Buttons/TextureButton5")
	]
	bgm = get_node("Audio")
	sfx = get_node("SFX")
	set_process(false)
	# 根节点拉伸模式
	anchors_preset = PRESET_FULL_RECT
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func set_scene_data(data: SceneData) -> void:
	current_data = data
	if current_data == null:
		push_warning("SceneViewer: received null SceneData")
		return

	# 背景
	background_rect.texture = current_data.background

	# 音乐
	if current_data.music:
		bgm.stream = current_data.music
		if not bgm.playing:
			bgm.play()
	else:
		bgm.stop()

	# 布局缩放
	content_size = current_data.design_size
	_update_layout_scale()

	# 清理旧按钮
	for c in buttons_root.get_children():
		c.queue_free()

	# 创建按钮
	# 设置按钮间距
	buttons_root.add_theme_constant_override("separation", 20)
	
	# 先隐藏所有按钮
	for btn in button_nodes:
		btn.visible = false
	
	# 根据数据显示和设置按钮
	var btn_index = 0
	for btn_data in current_data.buttons:
		if btn_index >= 5:  # 最多支持5个按钮
			break
			
		var btn = button_nodes[btn_index]
		btn.visible = btn_data.visible and btn_data.enabled
		if not btn.visible:
			btn_index += 1
			continue
			
		# 设置按钮属性
		btn.texture_normal = btn_data.texture
		btn.tooltip_text = btn_data.tooltip
		btn.custom_minimum_size = btn_data.size
		
		# 设置按钮位置（如果需要自定义位置而非在HBoxContainer中自动排列）
		if btn_data.position != Vector2.ZERO:
			btn.position = btn_data.position * scale_factor
		
		# 设置按钮大小
		btn.size = btn_data.size * scale_factor
		
		# 存储按钮数据以便后续使用
		btn.set_meta("data", btn_data)
		
		# 连接信号（如果之前已连接则先断开）
		if btn.is_connected("pressed", _on_button_pressed):
			btn.disconnect("pressed", _on_button_pressed)
		btn.connect("pressed", _on_button_pressed.bind(btn))
		
		btn_index += 1
		

	# 返回按钮
	back_button_node.visible = current_data.show_back_button
	if current_data.show_back_button:
		back_button_node.texture_normal = current_data.back_button_texture
		back_button_node.tooltip_text = current_data.back_button_tooltip
		back_button_node.custom_minimum_size = current_data.back_button_size
		back_button_node.position = current_data.back_button_position * scale_factor
		back_button_node.size = current_data.back_button_size * scale_factor

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_layout_scale()
		_relayout()

func _update_layout_scale() -> void:
	if current_data == null:
		return
	var viewport_size = get_viewport_rect().size
	if current_data.keep_aspect and current_data.design_size.x > 0.0 and current_data.design_size.y > 0.0:
		var scale_x = viewport_size.x / current_data.design_size.x
		var scale_y = viewport_size.y / current_data.design_size.y
		scale_factor = min(scale_x, scale_y)
	else:
		# 拉伸填充
		scale_factor = 1.0

	# 设置背景适配：使用 TextureRect 的 expand + stretch 模式
	background_rect.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_COVERED
	background_rect.anchor_left = 0.0
	background_rect.anchor_top = 0.0
	background_rect.anchor_right = 1.0
	background_rect.anchor_bottom = 1.0
	background_rect.offset_left = 0.0
	background_rect.offset_top = 0.0
	background_rect.offset_right = 0.0
	background_rect.offset_bottom = 0.0

func _relayout() -> void:
	if current_data == null:
		return
	# 重新应用缩放到按钮和返回按钮
	for btn in buttons_root.get_children():
		if btn is TextureButton:
			var data: SceneButtonData = null
			# 尝试从名称匹配 data（也可把 data 存在 metadata）
			# 更稳妥：在创建时 set_meta("data", btn_data)
			# 这里做兼容：
			
# 处理按钮点击事件
func _on_button_pressed(button: TextureButton) -> void:
	# 获取按钮关联的数据
	if not button.has_meta("data"):
		push_warning("Button pressed but has no associated data")
		return
		
	var btn_data = button.get_meta("data") as SceneButtonData
	if btn_data == null:
		push_warning("Button data is null or not SceneButtonData type")
		return
	
	# 播放点击音效（如果有）
	if btn_data.click_sound != null:
		sfx.stream = btn_data.click_sound
		sfx.play()
	
	# 如果有目标场景，通知场景导航器切换场景
	if btn_data.target_scene != null:
		# 发送信号或调用场景导航器的方法
		get_parent().call_deferred("navigate_to_scene", btn_data.target_scene)
	
	# 可以在这里添加其他按钮点击逻辑

func _on_back_pressed() -> void:
	if Game.g_scenes:
		Game.g_scenes.pop_scene()
