extends Node

const CONFIG_SECTION := "display"

const keep_aspect := "keep"
const vsync_enabled := true

# 内存中的当前设置
var is_fullscreen: bool = false
var window_size_index: int = 0
var window_size := [
	Vector2i(860, 540),
	Vector2i(1024, 576),
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1536, 864),
	Vector2i(1920, 1080)
]
var window_position: Vector2i = Vector2i(0, 31) # -1 表示不强制

# 上一次记录的窗口位置
var _last_window_position := Vector2i(0, 0)
# 检查窗口位置变化的计时器
var _position_check_timer := 0.0
# 检查窗口位置的时间间隔（秒）
const POSITION_CHECK_INTERVAL := 2.0

func _ready() -> void:
	_load_settings()
	_apply_settings()
	var win := _get_window()
	if not win.is_connected("size_changed", Callable(self, "_on_window_size_changed")):
		win.connect("size_changed", Callable(self, "_on_window_size_changed"))
	_last_window_position = win.position
	
func _input(event: InputEvent) -> void:
	# 检测是否按下F11键
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_F10:
				toggle_fullscreen()
				get_viewport().set_input_as_handled() # 标记事件为已处理，防止其他节点也处理此事件

func _get_window() -> Window:
	return get_tree().root

# 在窗口化时记录玩家调整的大小
func _on_window_size_changed() -> void:
	if is_fullscreen:
		return
	var win := _get_window()
	_set_window_size_index(win.size)
	_save_settings()
	
# 设置窗口大小索引为与给定大小最接近的预设大小
func _set_window_size_index(size: Vector2i) -> void:
	var closest_index := 0
	var min_distance := INF
	for i in range(window_size.size()):
		var preset_size = window_size[i] as Vector2i
		var dx = size.x - preset_size.x
		var dy = size.y - preset_size.y
		var distance = dx * dx + dy * dy
		if distance < min_distance:
			min_distance = distance
			closest_index = i
	window_size_index = closest_index

# 在_process中定期检查窗口位置变化
func _process(delta: float) -> void:
	if is_fullscreen:
		return
	_position_check_timer += delta
	if _position_check_timer >= POSITION_CHECK_INTERVAL:
		_position_check_timer = 0.0
		var win := _get_window()
		var current_position := win.position
		if current_position != _last_window_position and current_position.x >= 0 and current_position.y >= 0:
			_last_window_position = current_position
			window_position = current_position
			_save_settings()

# 对外 API：切换全屏（独占全屏）
func set_fullscreen(enable: bool) -> void:
	is_fullscreen = enable
	_apply_fullscreen_mode()
	_save_settings()

# 对外 API：在独占全屏与窗口化之间切换
func toggle_fullscreen() -> void:
	var enable := false if is_fullscreen else true
	set_fullscreen(enable)

# 对外 API：在窗口化模式下设置分辨率
func set_windowed_resolution(size_id: int) -> void:
	if size_id >= 0 and size_id < window_size.size() and not is_fullscreen:
		var win := _get_window()
		win.size = window_size[size_id]
		window_size_index = size_id
	_save_settings()

# 应用当前设置到窗口
func _apply_settings() -> void:
	_apply_fullscreen_mode()
	# 位置与尺寸（仅窗口化时）
	if not is_fullscreen:
		var win := _get_window()
		if window_position.x >= 0 and window_position.y >= 0:
			win.position = window_position

func _apply_fullscreen_mode() -> void:
	var win := _get_window()
	if is_fullscreen:
		win.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		win.mode = Window.MODE_WINDOWED
		if window_size_index < 0 or window_size_index >= window_size.size():
			window_size_index = 3
		win.size = window_size[window_size_index]
		win.borderless = false
		win.unresizable = false

# 读取/写入配置
func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(Game.CONFIG_PATH)
	if err != OK:
		return

	is_fullscreen = cfg.get_value(CONFIG_SECTION, "is_fullscreen", false)
	window_size_index = cfg.get_value(CONFIG_SECTION, "window_size_index", 0)
	var px: int = cfg.get_value(CONFIG_SECTION, "pos_x", -1)
	var py: int = cfg.get_value(CONFIG_SECTION, "pos_y", -1)
	window_position = Vector2i(px, py)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(Game.CONFIG_PATH)

	cfg.set_value(CONFIG_SECTION, "is_fullscreen", is_fullscreen)
	cfg.set_value(CONFIG_SECTION, "window_size_index", window_size_index)

	# 仅在窗口化时记录当前位置（部分 WM 不允许读位置，忽略错误）
	var win := _get_window()
	var pos := win.position
	if not is_fullscreen and pos.x >= 0 and pos.y >= 0:
		cfg.set_value(CONFIG_SECTION, "pos_x", pos.x)
		cfg.set_value(CONFIG_SECTION, "pos_y", pos.y)

	var err := cfg.save(Game.CONFIG_PATH)
	if err != OK:
		push_warning("Failed to save settings to %s (error %d)" % [Game.CONFIG_PATH, err])
