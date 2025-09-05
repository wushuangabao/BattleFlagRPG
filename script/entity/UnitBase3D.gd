# 负责单位的移动逻辑
class_name UnitBase3D extends Marker3D

@export var move_time: float = 0.5

signal initialized

var MAX_STEPS: int = 6 # 每次能移动的最大步数，-1表示无限制
var anim: AnimatedSprite3D = null
var map: Ground = null
var actor: ActorController = null

var _cell: Vector2i # 当前所在格子
var _dir: Vector2i # 当前朝向
var _target_cell: Vector2i # 移动目标格
var _is_moving := false
var _reachable: Dictionary = {} # cell->steps
var _current_path: Array[Vector2i] = []

func get_pos_2d() -> Vector2:
	return Vector2(global_position.x, global_position.z)
	
func get_cur_cell() -> Vector2i:
	return GridHelper.to_cell(map, get_pos_2d())

func set_cur_cell(cell: Vector2i, dir: Vector2i = Vector2i(1, 0)) -> void:
	if Game.Debug == 1:
		print("set cell ", cell.x, ", ", cell.y)
	_cell = cell
	_dir = dir
	
func set_target_cell(cell: Vector2i) -> bool:
	if not _is_moving:
		if MAX_STEPS == -1 or _reachable.has(cell):
			if cell != _target_cell:
				_target_cell = cell
				_update_path(true)
			else:
				_move_by_current_path()
			return true
	return false

func _ready() -> void:
	anim = get_child(0)
	anim.play(&"run")
	if map == null:
		push_error("unit base ready: not find map")
		return
	if _cell_walkable(_cell) == false:
		push_error("nit base ready: unwalkable")
		return
	global_position = GridHelper.to_world_player_3d(map, _cell)
	initialized.emit(self)

func on_selected() -> void:
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
				if next_cell.x < _cell.x and not anim.flip_h:
					anim.flip_h = true
				elif next_cell.x > _cell.x and anim.flip_h:
					anim.flip_h = false
		return

func _update_path(preview: bool):
	if not _reachable.has(_target_cell):
		_current_path.clear()
		map.clear_path()
		return
	var path = GridHelper.a_star(_cell, _target_cell, _dir, _cell_walkable)
	# A* 可能返回空（理论上不会，因为 _target_cell 在可达范围内，但以防万一）
	if path.size() == 0:
		_current_path.clear()
		map.clear_path()
		return
	# 安全起见，截断超过 MAX_STEPS 的路径
	if MAX_STEPS != -1:
		if path.size() - 1 > MAX_STEPS:
			path = path.slice(0, MAX_STEPS + 1)
	_current_path = path
	if preview:
		map.set_path(_current_path)

func _cell_walkable(c: Vector2i) -> bool:
	var source_id = map.get_cell_source_id(c)
	if source_id == -1:
		return false
	# 在 TileSet 的该Tile里添加了自定义数据 "walkable"
	var data = map.get_cell_tile_data(c)
	if data and data.has_custom_data("walkable") and data.get_custom_data("walkable") == true:
		return true
	return false

func _move_by_current_path():
	if _current_path.size() <= 1:
		return
	_is_moving = true
	map.set_reachable({}) # 移动时不显示可达范围
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 跳过起点
	for i in range(1, _current_path.size()):
		var c = _current_path[i]
		tween.tween_property(self, "global_position", GridHelper.to_world_player_3d(map, c), move_time)
		tween.tween_callback(func(): _cell = c) # 每到一个格子就更新位置
	tween.finished.connect(func():
		_cell = _current_path.back() # 不要立刻设置_cell到目标位置，要等移动完
		_is_moving = false
		# 移动完刷新可达范围（从新位置出发）
		_compute_reachable()
		_current_path.clear()
		map.clear_path())
