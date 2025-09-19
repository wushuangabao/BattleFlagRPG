extends Node

const CONFIG_PATH := "user://settings.cfg"
const CONFIG_SECTION := "display"

# 内存中的当前设置
var is_fullscreen: bool = true
var window_size: Vector2i = Vector2i(1920, 1080)
var window_position: Vector2i = Vector2i(0, 0) # -1 表示不强制
var keep_aspect: String = "keep"  # "keep", "expand", "ignore"
var vsync_enabled: bool = true


func _ready() -> void:
	_load_settings()
	_apply_settings()
	_connect_window_signals()
	
func _input(event: InputEvent) -> void:
	# 检测是否按下ESC键，并且当前处于全屏模式
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			if is_fullscreen:
				# 退出全屏，切换到窗口模式
				set_fullscreen(false)
				# 标记事件为已处理，防止其他节点也处理此事件
				get_viewport().set_input_as_handled()

func _get_window() -> Window:
	return get_tree().root

func _connect_window_signals() -> void:
	var win := _get_window()
	if not win.is_connected("size_changed", Callable(self, "_on_window_size_changed")):
		win.connect("size_changed", Callable(self, "_on_window_size_changed"))
	if not win.is_connected("window_state_changed", Callable(self, "_on_window_state_changed")):
		win.connect("window_state_changed", Callable(self, "_on_window_state_changed"))
	if not win.is_connected("dpi_changed", Callable(self, "_on_dpi_changed")):
		win.connect("dpi_changed", Callable(self, "_on_dpi_changed"))

func _on_window_size_changed() -> void:
	var win := _get_window()
	# 仅在窗口化时记录玩家调整的大小
	if not is_fullscreen:
		window_size = win.size
		_save_settings()

func _on_window_state_changed() -> void:
	# 当用户通过系统快捷键切换全屏、最大化等状态时触发
	var win := _get_window()
	# 这里根据当前 Window 的状态回填（示例里我们主要使用 exclusive_fullscreen/borderless）
	# 如果你允许 Alt+Enter 切换，可以在 Input 里调用 toggle_fullscreen()
	# 这里简单保存一下尺寸变化（窗口化时）
	if not is_fullscreen:
		window_size = win.size
	_save_settings()

func _on_dpi_changed() -> void:
	# DPI 改变时通常无需保存，但如需自适应 UI，可在此处理
	pass

# 对外 API：切换全屏（独占全屏）
func set_fullscreen(enable: bool) -> void:
	is_fullscreen = enable
	_apply_fullscreen_mode()
	_save_settings()

func toggle_fullscreen() -> void:
	# 在独占全屏与窗口化之间切换
	set_fullscreen(!is_fullscreen)

# 对外 API：在窗口化模式下设置分辨率
func set_windowed_resolution(size: Vector2i) -> void:
	window_size = size.clamp(Vector2i(640, 360), Vector2i(16384, 16384))
	if not is_fullscreen:
		var win := _get_window()
		win.size = window_size
	_save_settings()

# 对外 API：设置是否启用 VSync
func set_vsync(enable: bool) -> void:
	vsync_enabled = enable
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enable else DisplayServer.VSYNC_DISABLED
	)
	_save_settings()

# 对外 API：设置保持纵横比
func set_keep_aspect(mode: String) -> void:
	# mode: "keep", "expand", "ignore"
	keep_aspect = mode
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = (
		Window.CONTENT_SCALE_ASPECT_KEEP if mode == "keep"
		else Window.CONTENT_SCALE_ASPECT_EXPAND if mode == "expand"
		else Window.CONTENT_SCALE_ASPECT_IGNORE
	)
	_save_settings()

# 应用当前设置到窗口
func _apply_settings() -> void:
	var win := _get_window()

	# VSync
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)

	# 纵横比策略
	set_keep_aspect(keep_aspect)

	# 全屏/窗口化
	_apply_fullscreen_mode()

	# 位置与尺寸（仅窗口化时）
	if not is_fullscreen:
		win.size = window_size
		if window_position.x >= 0 and window_position.y >= 0:
			win.position = window_position

func _apply_fullscreen_mode() -> void:
	var win := _get_window()
	# 先复位窗口属性，避免状态残留
	win.borderless = false
	win.mode = Window.MODE_WINDOWED
	win.unresizable = false

	if is_fullscreen:
		# 独占全屏（切换显示器分辨率；最稳定的“真全屏”）
		win.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		# 恢复窗口化
		win.mode = Window.MODE_WINDOWED
		win.size = window_size

# 读取/写入配置
func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err != OK:
		return

	is_fullscreen = cfg.get_value(CONFIG_SECTION, "is_fullscreen", false)
	var w: int = cfg.get_value(CONFIG_SECTION, "width", 1280)
	var h: int = cfg.get_value(CONFIG_SECTION, "height", 720)
	window_size = Vector2i(w, h)
	var px: int = cfg.get_value(CONFIG_SECTION, "pos_x", -1)
	var py: int = cfg.get_value(CONFIG_SECTION, "pos_y", -1)
	window_position = Vector2i(px, py)
	keep_aspect = str(cfg.get_value(CONFIG_SECTION, "keep_aspect", "keep"))
	vsync_enabled = cfg.get_value(CONFIG_SECTION, "vsync", true)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH) # 如果不存在也没关系

	cfg.set_value(CONFIG_SECTION, "is_fullscreen", is_fullscreen)
	cfg.set_value(CONFIG_SECTION, "width", window_size.x)
	cfg.set_value(CONFIG_SECTION, "height", window_size.y)

	# 仅在窗口化时记录当前位置（部分 WM 不允许读位置，忽略错误）
	var win := _get_window()
	var pos := win.position
	if not is_fullscreen and pos.x >= 0 and pos.y >= 0:
		cfg.set_value(CONFIG_SECTION, "pos_x", pos.x)
		cfg.set_value(CONFIG_SECTION, "pos_y", pos.y)

	cfg.set_value(CONFIG_SECTION, "keep_aspect", keep_aspect)
	cfg.set_value(CONFIG_SECTION, "vsync", vsync_enabled)

	var err := cfg.save(CONFIG_PATH)
	if err != OK:
		push_warning("Failed to save settings to %s (error %d)" % [CONFIG_PATH, err])
