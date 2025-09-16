# 负责单位的移动逻辑
class_name UnitBase3D extends Marker3D

@export var move_time: float = 0.5
@onready var anim: AnimatedSprite3D = $anim
@onready var bar_hp: TextureProgressBar = $SubViewport/HP
@onready var bar_mp: TextureProgressBar = $SubViewport/MP

signal initialized

var map: Ground = null
var actor: ActorController = null

var _cell: Vector2i # 当前所在格子
var _dir: Vector2i # 当前朝向
var _target_cell = Vector2i(-1, -1)# 移动目标格
var _is_moving := false
var _reachable: Dictionary = {} # cell->steps
var _current_path: Array[Vector2i] = []

var _tween_hp : Tween
var _tween_mp : Tween

func get_pos_2d() -> Vector2:
	return Vector2(global_position.x, global_position.z)

func get_cur_cell() -> Vector2i:
	return _cell

func _get_cur_cell() -> Vector2i:
	return GridHelper.to_cell(map, get_pos_2d())

func get_cur_path() -> Array[Vector2i]:
	return _current_path

func set_cur_cell(cell: Vector2i, dir: Vector2i = Vector2i(1, 0)) -> void:
	_cell = cell
	_dir = dir

func is_target_cell(cell: Vector2i) -> bool:
	return cell == _target_cell
	
func set_target_cell(cell: Vector2i) -> bool:
	if not _is_moving and cell != _cell and actor.get_state() != ActorController.ActorState.DoAction:
		if _reachable.has(cell):
			if not is_target_cell(cell) or _current_path.size() == 0:
				_target_cell = cell
				_update_path(true)
			return true
	return false

func _ready() -> void:
	anim.play(&"idle")
	if map == null:
		push_error("unit base ready: not find map")
		return
	if _cell_walkable(_cell) == false:
		push_error("unit base ready: unwalkable")
		return
	global_position = GridHelper.to_world_player_3d(map, _cell)
	initialized.emit(self) # _on_cur_actor_initialized

func on_selected() -> void:
	if actor.get_state() != ActorController.ActorState.DoAction:
		_compute_reachable()

func _compute_reachable():
	_reachable = GridHelper.movement_range(_cell, actor.get_AP(), _cell_walkable)
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
		var a = Game.g_combat.get_actor_on_cell(c)
		if not a:
			return true
	return false

func move_by_current_path():
	if _current_path.size() <= 1:
		return
	if is_target_cell(_cell):
		return
	_is_moving = true
	anim.play(&"run")
	map.clear_on_cur_actor_move()
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)	
	# 跳过起点
	for i in range(1, _current_path.size()):
		var c = _current_path[i]
		tween.tween_property(self, ^"global_position", GridHelper.to_world_player_3d(map, c), move_time)
		tween.tween_callback(func(): _cell = c) # 每到一个格子就更新位置
	tween.finished.connect(func():
		_cell = _target_cell # 不要立刻设置_cell到目标位置，要等移动完
		_is_moving = false
		anim.play(&"idle")
		_current_path.clear()
		map.clear_path()
	)

func is_arrived_target_cell() -> bool:
	return is_target_cell(_cell)

func _animate_bar(bar: TextureProgressBar, tween: Tween, to_value: float, duration: float) -> void:
	to_value = clampf(to_value, bar.min_value, bar.max_value)
	var from_value := bar.value
	if is_equal_approx(from_value, to_value):
		return
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(t):
		bar.set_value_no_signal(lerp(from_value, to_value, t))
		, 0.0, 1.0, duration
	)

func animate_hp_bar(to_value: float, duration := 0.5):
	if _tween_hp and _tween_hp.is_running():
		_tween_hp.kill()
	_animate_bar(bar_hp, _tween_hp, to_value, duration)

func animate_mp_bar(to_value: float, duration := 0.5):
	if _tween_mp and _tween_hp.is_running():
		_tween_mp.kill()
	_animate_bar(bar_mp, _tween_mp, to_value, duration)