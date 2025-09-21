# 负责检测鼠标位于哪个屏幕区域
# 子节点只能使用 CollisionShape2D 类型的矩形
class_name UI_Area_Detector
extends Area2D

@export var cursor_texture_up: Texture2D
@export var cursor_texture_upleft: Texture2D
@export var cursor_texture_width := 20

@onready var mouse_sprite : Sprite2D

var inside_children : Array[CollisionShape2D] # 在哪些子节点的区域内

var cursor_place : Vector2i

# 旋转/翻转向量的辅助函数，使偏移与纹理变换一致
func _rot90_cw(v: Vector2) -> Vector2:
	return Vector2(v.y, -v.x)

func _rot90_ccw(v: Vector2) -> Vector2:
	return Vector2(-v.y, v.x)

func _flip_y(v: Vector2) -> Vector2:
	return Vector2(v.x, -v.y)

# 通过变换cursor_texture_up与cursor_texture_upleft获取其他方向的纹理
func _get_transformed_texture(direction: Vector2i) -> Texture2D:
	# 基准：
	# - 正方向基于 cursor_texture_up（上）
	# - 对角方向基于 cursor_texture_upleft（左上）
	if direction == Vector2i(0, -1):  # 上
		return cursor_texture_up
	if direction == Vector2i(-1, -1):  # 左上
		return cursor_texture_upleft

	# 正方向（上、下、左、右）
	if direction == Vector2i(1, 0):  # 右
		var img_r := cursor_texture_up.get_image()
		img_r.rotate_90(CLOCKWISE)
		return ImageTexture.create_from_image(img_r)
	elif direction == Vector2i(-1, 0):  # 左
		var img_l := cursor_texture_up.get_image()
		img_l.rotate_90(COUNTERCLOCKWISE)
		return ImageTexture.create_from_image(img_l)
	elif direction == Vector2i(0, 1):  # 下
		var img_d := cursor_texture_up.get_image()
		img_d.flip_y()
		return ImageTexture.create_from_image(img_d)

	# 对角方向（左上、右上、右下、左下）
	if direction == Vector2i(1, -1):  # 右上
		var img_ur := cursor_texture_upleft.get_image()
		img_ur.rotate_90(CLOCKWISE)
		return ImageTexture.create_from_image(img_ur)
	elif direction == Vector2i(1, 1):  # 右下
		var img_dr := cursor_texture_upleft.get_image()
		img_dr.rotate_180()
		return ImageTexture.create_from_image(img_dr)
	elif direction == Vector2i(-1, 1):  # 左下
		var img_dl := cursor_texture_upleft.get_image()
		img_dl.rotate_90(COUNTERCLOCKWISE)
		return ImageTexture.create_from_image(img_dl)
	
	return cursor_texture_up

# 与纹理变换一致的“尖端偏移”计算，使箭头尖端对准鼠标
# 注意：当前 mouse_sprite.centered = false（左上角为锚点）
func _get_transformed_offset(direction: Vector2i) -> Vector2:
	match direction:
		# 正方向
		Vector2i(0, -1):  # 上方向：直接使用基准贴图 cursor_texture_up 的尖端像素坐标
			return -Vector2(cursor_texture_width * 0.5, 0)
		Vector2i(1, 0):   # 右
			return -Vector2(cursor_texture_width, cursor_texture_width * 0.5)
		Vector2i(-1, 0):  # 左
			return -Vector2(0, cursor_texture_width * 0.5)
		Vector2i(0, 1):   # 下
			return -Vector2(cursor_texture_width * 0.5, cursor_texture_width)
			
		# 对角方向
		Vector2i(-1, -1): # 左上方向：直接使用基准贴图 cursor_texture_upleft 的尖端像素坐标
			return Vector2.ZERO
		Vector2i(1, -1):  # 右上
			return -Vector2(cursor_texture_width, 0)
		Vector2i(1, 1):   # 右下
			return -Vector2(cursor_texture_width, cursor_texture_width)
		Vector2i(-1, 1):  # 左下
			return -Vector2(0, cursor_texture_width)
			
		_:  # 默认情况
			return Vector2.ZERO

func _ready() -> void:
	mouse_sprite = get_node(^"/root/Game/mouse_layer/mouse_sprite")
	inside_children = []
	var cnt = get_child_count()
	var i = 0
	while i < cnt:
		var child = get_child(i)
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			if _check_mouse_in(child):
				inside_children.append(child)
			i += 1
		else:
			print("警告：UI_Area_Detector 的子节点类型错误！", i)
	_update_cursor_place()

func _update_cursor_place() -> void:
	cursor_place = Vector2i.ZERO
	if inside_children.size() == 0:
		mouse_sprite.texture = mouse_sprite.texture_normal
		mouse_sprite.offset = mouse_sprite.offset_fix
		return
	for child in inside_children:
		match child.get_index():
			0:
				cursor_place.x -= 1
			1:
				cursor_place.x += 1
			2:
				cursor_place.y -= 1
			3:
				cursor_place.y += 1
	if cursor_place == Vector2i.ZERO:
		mouse_sprite.texture = mouse_sprite.texture_normal
		mouse_sprite.offset = mouse_sprite.offset_fix
	else:
		# 使用纹理变换函数获取对应方向的纹理，并同步设置尖端偏移
		mouse_sprite.texture = _get_transformed_texture(cursor_place)
		mouse_sprite.offset = _get_transformed_offset(cursor_place)

# 当鼠标进入碰撞形状时自动调用
func _mouse_shape_enter(shape_idx: int):
	var shape = get_child(shape_idx)
	if not shape in inside_children:
		inside_children.append(shape)
		_update_cursor_place()
		if Game.Debug == 1:
			print("鼠标进入区域：", shape_idx)
			#print("鼠标位置: ", get_global_mouse_position())

# 当鼠标离开碰撞形状时自动调用  
func _mouse_shape_exit(shape_idx: int):
	var shape = get_child(shape_idx)
	if not shape:
		push_error("鼠标离开区域 ", shape_idx, " 为空子节点")
		return
	if shape in inside_children:
		if _check_mouse_in(shape) == false:
			inside_children.erase(shape)
			_update_cursor_place()
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
	if _get_child_rect_local(shape).has_point(mouse_pos):
		return true
	else:
		return false

#func _draw() -> void:
	#if Game.Debug == 1:
		## 画每个子节点的矩形
		#for child in get_children():
			#var rect = _get_child_rect_local(child)
			#draw_rect(rect, Color(1, 0, 0), false, 1.0)

func _process(_delta: float) -> void:
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
	
