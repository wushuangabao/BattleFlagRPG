class_name Camera3D_movable extends Camera3D

#@export var move_sensitivity := 0.001      # 移动灵敏度
#@export var sensitivity      := 0.001      # 旋转灵敏度
@export var edge_threshold   := 25.0       # 屏幕边缘区域的像素大小
@export var move_speed       := 10.0       # 镜头移动速度
@export var dist_to_target   := 14.0       # 相机到目标的距离（初始值）
@export var fix_dz_to_target := -0.5
@export var follow_target    : Node3D      # 跟随目标
@export var ui_area_detector : UI_Area_Detector

# 当前极坐标（水平角 yaw，垂直角 pitch）
var _yaw   := 0.0
var _pitch := 0.9
#var _is_moving   := false
#var _is_rotating := false
var _moving_to_target := false       # 镜头正在移动到目标。此时不能主动移动镜头
var _is_follow_target_moving = false # 镜头正在跟随目标移动。可以被主动移动打断

func set_target_immediately(t: Node3D) -> void:
	follow_target = t
	_update_camera()
	
func set_target_gradually(t: Node3D) -> void:
	if follow_target != t:
		follow_target = t
		_moving_to_target = true

func follow_target_moving(t: Node3D) -> void:
	follow_target = t
	_is_follow_target_moving = true
	if _moving_to_target:
		_moving_to_target = false
	#print("相机：开始跟随目标移动")

#func _unhandled_input(event: InputEvent) -> void:
	## 开始拖拽
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_RIGHT:
			#if event.pressed:
				#_is_moving = true
			#get_viewport().set_input_as_handled() #标记输入事件为已处理

func _process(delta) -> void:
	if not _moving_to_target and not ui_area_detector.is_mouse_inside:
		var viewport := get_viewport()
		var viewport_rect := viewport.get_visible_rect()
		var mouse_pos := viewport.get_mouse_position()
		if viewport_rect.grow(15.0).has_point(mouse_pos): # 鼠标没有超出视口15.0
			var move_direction := Vector3.ZERO
			var viewport_size := viewport_rect.size
			if mouse_pos.x < edge_threshold:
				move_direction.x -= 1  # 向左移动
			elif mouse_pos.x > viewport_size.x - edge_threshold:
				move_direction.x += 1  # 向右移动
			if mouse_pos.y < edge_threshold:
				move_direction.z -= 1  # 向前移动
			elif mouse_pos.y > viewport_size.y - edge_threshold:
				move_direction.z += 1  # 向后移动
			if move_direction.length() > 0.1:
				if _is_follow_target_moving:
					#print("相机：停止跟随目标移动")
					_is_follow_target_moving = false
					return
				var mv = move_direction.normalized() * move_speed * delta
				global_position += mv
				return
	if follow_target == null:
		return
	if _moving_to_target or _is_follow_target_moving:
		var target_pos = follow_target.global_position
		target_pos.z += fix_dz_to_target
		var my_target_pos = _get_my_pos_by(target_pos)
		var e = my_target_pos.distance_squared_to(global_position)
		if e < 0.1:
			#print("e = ", e)
			_moving_to_target = false
			if _is_follow_target_moving and follow_target.get("_is_moving"):
				_is_follow_target_moving = follow_target._is_moving
		else:
			var lerp_factor = clamp(e * 0.02, 0.02, 0.05)
			#print("lerp_factor = ", lerp_factor)
			global_position = global_position.lerp(my_target_pos, lerp_factor)

func _update_camera() -> void:
	var target = follow_target.global_position
	target.z += fix_dz_to_target
	global_position = _get_my_pos_by(target)
	look_at(target, Vector3.UP)

# 聚焦到 p 时，相机的坐标
func _get_my_pos_by(p: Vector3) ->Vector3:
	var v := Vector3(
		dist_to_target * cos(_pitch) * sin(_yaw),
		dist_to_target * sin(_pitch),
		dist_to_target * cos(_pitch) * cos(_yaw)
	)
	return p + v
