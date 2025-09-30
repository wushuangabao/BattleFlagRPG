class_name SceneViewer extends Control

var background_rect: TextureRect
var buttons_root: HBoxContainer
var button_nodes: Array[TextureButton]
var back_button_node: TextureButton
var bgm: AudioStreamPlayer
var sfx: AudioStreamPlayer

var current_data: SceneData

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
	# 先隐藏所有按钮
	for btn in button_nodes:
		if btn.visible:
			if btn.is_connected("pressed", _on_button_pressed):
				btn.disconnect("pressed", _on_button_pressed)
			btn.visible = false
	back_button_node.visible = false
	# 背景
	background_rect.texture = current_data.background
	# 音乐
	if current_data.music:
		bgm.stream = current_data.music
		if not bgm.playing:
			bgm.play()
	else:
		bgm.stop()

func show_buttons() -> void:
	if current_data == null:
		return
	var btn_index = 0
	for btn_data in current_data.buttons:
		if btn_index >= 5:  # 最多支持5个按钮
			break
		var btn = button_nodes[btn_index]
		# 设置按钮属性但先不显示
		btn.modulate.a = 0  # 完全透明
		btn.visible = btn_data.visible and btn_data.enabled
		if not btn.visible:
			btn_index += 1
			continue
		btn.texture_normal = btn_data.texture
		btn.tooltip_text = btn_data.tooltip
		btn.set_meta("data", btn_data)
		if btn.is_connected("pressed", _on_button_pressed):
			btn.disconnect("pressed", _on_button_pressed)
		btn.connect("pressed", _on_button_pressed.bind(btn))
		
		# 创建浮现动画
		var tween = create_tween()
		tween.tween_property(btn, "modulate:a", 1.0, 0.8).set_delay(btn_index * 0.2)  # 按顺序延迟显示
		
		btn_index += 1
	
	# 返回按钮
	back_button_node.visible = current_data.show_back_button
	if current_data.show_back_button:
		back_button_node.modulate.a = 0  # 完全透明
		back_button_node.texture_normal = current_data.back_button_texture
		back_button_node.tooltip_text = current_data.back_button_tooltip
		
		# 为返回按钮添加浮现动画，稍晚于其他按钮
		var back_tween = create_tween()
		back_tween.tween_property(back_button_node, "modulate:a", 1.0, 0.5).set_delay(btn_index * 0.2)

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
	
	# 如果有目标场景，则进入该场景
	if btn_data.target_scene != null:
		if Game.g_scenes:
			Game.g_scenes.push_scene(btn_data.target_scene)

func _on_back_pressed() -> void:
	if Game.g_scenes:
		Game.g_scenes.pop_scene()
