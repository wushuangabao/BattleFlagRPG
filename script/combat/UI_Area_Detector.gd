# 负责检测鼠标位于哪个屏幕区域
# 子节点只能使用 CollisionShape2D 类型的矩形
class_name UI_Area_Detector
extends Area2D

var is_mouse_inside  := false # 鼠标是否在某个区域内
# var is_mouse_in_game := true  # 鼠标是否在游戏内
var _inside_child_id := 0	  # 在第几个子节点的区域内

func _ready() -> void:
	var cnt = get_child_count()
	var i = 0
	while i < cnt:
		var child = get_child(i)
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			if _check_mouse_in(child):
				_inside_child_id = i
				is_mouse_inside = true
				return
			i += 1
		else:
			print("警告：UI_Area_Detector 的子节点类型错误！", i)
			child.queue_free()
			remove_child(i)
			cnt -= 1
		
	is_mouse_inside = false

# 当鼠标进入碰撞形状时自动调用
func _mouse_shape_enter(shape_idx: int):
	if _inside_child_id != shape_idx or is_mouse_inside == false:
		is_mouse_inside = true
		_inside_child_id = shape_idx
		if Game.Debug == 1:
			print("鼠标进入区域：", shape_idx)
			#print("鼠标位置: ", get_global_mouse_position())

# 当鼠标离开碰撞形状时自动调用  
func _mouse_shape_exit(shape_idx: int):
	if shape_idx != _inside_child_id:
		push_error("鼠标离开区域 ", shape_idx, "!=", _inside_child_id)
		return
	var shape = get_child(_inside_child_id)
	if not shape:
		push_error("鼠标离开区域 ", _inside_child_id, " 为空子节点")
		return
	if _check_mouse_in(shape) == false:
		is_mouse_inside = false
		if Game.Debug == 1:
			print("鼠标离开区域：", shape_idx)
	elif Game.Debug == 1:
		print("鼠标在区域内的 Control 节点上")

# 手动检测鼠标是否在区域内
func _check_mouse_in(shape : CollisionShape2D) -> bool:
	if !Game.is_mouse_in_viewport(get_viewport()):
		if Game.Debug == 1:
			print("鼠标离开窗口")
		return false
	var mouse_pos = to_local(get_global_mouse_position())
	# var point_transform = Transform2D(0, mouse_pos)
	# var point_shape = CircleShape2D.new()
	# point_shape.radius = 1
	#if shape.get_shape().collide(shape.global_transform, point_shape, point_transform):
	# 区域检测（不用碰撞检测）
	if _get_child_rect_local(shape).has_point(mouse_pos):
		return true
	else:
		return false

func _draw() -> void:
	if Game.Debug == 0:
		return
	# 画每个子节点的矩形
	for child in get_children():
		var rect = _get_child_rect_local(child)
		draw_rect(rect, Color(1, 0, 0), false, 1.0)
	# 画鼠标位置
	var mouse_pos = to_local(get_global_mouse_position())
	draw_circle(mouse_pos, 2.5, Color(0, 1, 0))

func _process(_delta: float) -> void:
	if Game.Debug == 0:
		return
	queue_redraw()

func _get_child_rect_local(child: CollisionShape2D) -> Rect2:
	var rect_shape := child.shape as RectangleShape2D
	var half_size: Vector2 = rect_shape.size * 0.5
	# 在 CollisionShape2D 的本地坐标系中的矩形四角（未旋转、未位移）
	var local_corner := Vector2(-half_size.x, -half_size.y)
	# 先将角点变到该 CollisionShape2D 的全局空间
	var corner_to_world = child.global_transform * local_corner
	# 再把世界坐标转换到 UI_Area_Detector 的本地坐标系
	var corner_local_to_self := to_local(corner_to_world)
	return Rect2(corner_local_to_self, rect_shape.size)
	
