extends AnimatedSprite2D

@export var MAX_STEPS: int = 6 # 每次能移动的最大步数，-1表示无限制
@export var move_time: float = 0.5
@export var map: Ground = null

var _cell: Vector2i # 当前所在格子
var _dir: Vector2i # 当前朝向
var _hover_cell: Vector2i # 鼠标悬停的格子
var _is_moving := false
var _reachable: Dictionary = {} # cell->steps
var _current_path: Array[Vector2i] = []

func _ready():	
	_dir = Vector2i(1, 0)
	
	# 初始化位置到最近的格子中心
	if map == null:
		map = get_node("../Ground")
	_cell = GridHelper.to_cell(map, global_position)
	global_position = GridHelper.to_world_player_2d(map, _cell)
	_compute_reachable()

func _compute_reachable():
	_reachable = GridHelper.movement_range(_cell, MAX_STEPS, _cell_walkable)
	map.set_reachable(_reachable)

func _process(_delta):
	if _is_moving:
		# 根据移动向左还是向右，翻转角色
		if _current_path.size() > 1:
			var idx = _current_path.find(_cell)
			if idx != -1 and idx < _current_path.size() - 1:
				var next_cell = _current_path[idx + 1]
				_dir = next_cell - _cell
				if next_cell.x < _cell.x and not flip_h:
					flip_h = true
				elif next_cell.x > _cell.x and flip_h:
					flip_h = false
		play("run")
		map.set_reachable({}) # 移动时不显示可达范围
		return
	else:
		#stop() # 停止动画会回到第一帧，看起来不自然
		play("run")
	# 预览路径
	var mouse_cell = GridHelper.to_cell(map, get_global_mouse_position())
	if mouse_cell != _hover_cell:
		_hover_cell = mouse_cell
		_update_path_preview()

func _unhandled_input(event):
	if _is_moving:
		return
	if MAX_STEPS != -1:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 只有在可达范围内才移动
			if _reachable.has(_hover_cell):
				_move_by_current_path()
	else:
		if event.is_action_pressed("ui_up"):
			_try_move(Vector2i(0, -1))
		elif event.is_action_pressed("ui_down"):
			_try_move(Vector2i(0, 1))
		elif event.is_action_pressed("ui_left"):
			_try_move(Vector2i(-1, 0))
		elif event.is_action_pressed("ui_right"):
			_try_move(Vector2i(1, 0))
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var target_cell = GridHelper.to_cell(map, get_global_mouse_position())
			_move_by_path(target_cell)

func _update_path_preview():
	if not _reachable.has(_hover_cell):
		_current_path.clear()
		map.clear_path()
		return
	var path = GridHelper.a_star(_cell, _hover_cell, _dir, _cell_walkable)
	# A* 可能返回空（理论上不会，因为 _hover_cell 在可达范围内，但以防万一）
	if path.size() == 0:
		_current_path.clear()
		map.clear_path()
		return
	# 安全起见，截断超过 MAX_STEPS 的路径
	if MAX_STEPS != -1:
		if path.size() - 1 > MAX_STEPS:
			path = path.slice(0, MAX_STEPS + 1)
	_current_path = path
	map.set_path(_current_path)

func _try_move(dir: Vector2i):
	var target = _cell + dir
	if not _cell_walkable(target):
		return
	_move_to_cell(target)

func _cell_walkable(c: Vector2i) -> bool:
	var source_id = map.get_cell_source_id(c)
	if source_id == -1:
		return false
	# 在 TileSet 的该Tile里添加了自定义数据 "walkable"
	var data = map.get_cell_tile_data(c)
	if data and data.has_custom_data("walkable") and data.get_custom_data("walkable") == true:
		return true
	return false

func _move_to_cell(target: Vector2i):
	_is_moving = true
	_cell = target
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", GridHelper.to_world_player_2d(map, _cell), move_time)
	tween.finished.connect(func():
		_is_moving = false)

func _move_by_path(target: Vector2i):
	var path: Array[Vector2i] = GridHelper.a_star(_cell, target, _dir, _cell_walkable)
	if path.size() <= 1:
		return
	_is_moving = true
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for c in path.slice(1): # 跳过起点
		tween.tween_property(self, "global_position", GridHelper.to_world_player_2d(map, c), move_time)
	_cell = target
	tween.finished.connect(func(): _is_moving = false)

func _move_by_current_path():
	if _current_path.size() <= 1:
		return
	_is_moving = true
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 跳过起点
	for i in range(1, _current_path.size()):
		var c = _current_path[i]
		tween.tween_property(self, "global_position", GridHelper.to_world_player_2d(map, c), move_time)
		tween.tween_callback(func(): _cell = c) # 每到一个格子就更新位置
	tween.finished.connect(func():
		_cell = _current_path.back() # 不要立刻设置_cell到目标位置，要等移动完
		_is_moving = false
		# 移动完刷新可达范围（从新位置出发）
		_compute_reachable()
		_current_path.clear()
		map.clear_path())
