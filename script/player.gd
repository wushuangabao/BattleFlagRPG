extends AnimatedSprite2D

@export var move_time: float = 0.5

var cell: Vector2i
var map: TileMapLayer
var is_moving := false

func _ready():
	# 初始格取自当前世界坐标
	map = get_node("../Ground")
	cell = GridHelper.to_cell(map, global_position)
	global_position = GridHelper.to_world_center(map, cell)

func _process(_delta):
	if is_moving:
		play("run")
	else:
		#stop()
		play("run")

func _unhandled_input(event):
	if is_moving:
		return
	if event.is_action_pressed("ui_up"):
		_try_move(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		_try_move(Vector2i(0, 1))
	elif event.is_action_pressed("ui_left"):
		_try_move(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		_try_move(Vector2i(1, 0))

func _try_move(dir: Vector2i):
	var target = cell + dir
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
	is_moving = true
	cell = target
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", GridHelper.to_world_center(map, cell), move_time)
	tween.finished.connect(func():
		is_moving = false)
