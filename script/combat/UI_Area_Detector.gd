class_name UI_Area_Detector
extends Area2D

var is_mouse_inside  := false
var _inside_child_id := 0

func _ready() -> void:
	var cnt = get_child_count()
	var i = 0
	while i < cnt:
		var shape = get_child(i)
		if _check_mouse_in(shape):
			_inside_child_id = i
			is_mouse_inside = true
			return
		i += 1
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
	if !get_viewport().get_visible_rect().has_point(get_viewport().get_mouse_position()):
		if Game.Debug == 1:
			print("鼠标离开窗口")
		return false
	# 创建一个圆形代表鼠标位置
	var mouse_pos = get_global_mouse_position()
	var point_transform = Transform2D(0, mouse_pos)
	var point_shape = CircleShape2D.new()
	point_shape.radius = 1
	# 区域检测（不用碰撞检测）
	#if shape.get_shape().collide(shape.global_transform, point_shape, point_transform):
	if shape.shape.get_rect().has_point(mouse_pos):
		queue_redraw()
		return true
	else:
		return false

func _draw() -> void:
	var mouse_pos = get_global_mouse_position()
	var shape = get_child(_inside_child_id)
	draw_circle(mouse_pos, 1, Color(0, 1, 0))
	draw_rect(shape.shape.get_rect(), Color(1, 0, 0), false, 1.0)
