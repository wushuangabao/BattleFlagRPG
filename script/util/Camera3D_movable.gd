extends Camera3D

#@export var move_sensitivity := 0.001      # 移动灵敏度
#@export var sensitivity      := 0.001      # 旋转灵敏度
@export var edge_threshold   := 25.0       # 屏幕边缘区域的像素大小
@export var move_speed       := 10.0       # 镜头移动速度
@export var dist_to_target   := 14.0       # 相机到目标的距离（初始值）
@export var fix_dz_to_target := -3.0
@export var follow_target    : Node3D      # 跟随目标
@export var ui_area_detector : UI_Area_Detector

# 到 follow_target 的偏移向量
var _dx_to_target := 0.0
var _dz_to_target := fix_dz_to_target

# 当前极坐标（水平角 yaw，垂直角 pitch）
var _yaw   := 0.0
var _pitch := 0.9
#var _is_moving   := false
#var _is_rotating := false
var _moving_to_target := false

func set_target_immediately(t: Node3D) -> void:
	follow_target = t
	_dx_to_target = 0.0
	_dz_to_target = fix_dz_to_target
	_update_camera()
	look_at(t.global_position, Vector3.UP)
	
func set_target_gradually(t: Node3D) -> void:
	if follow_target != t:
		follow_target = t
		_moving_to_target = true
	_dx_to_target = 0.0
	_dz_to_target = fix_dz_to_target

#func _unhandled_input(event: InputEvent) -> void:
	## 开始拖拽
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_RIGHT:
			#if event.pressed:
				#_is_moving = true
			#get_viewport().set_input_as_handled() #标记输入事件为已处理

func _process(delta) -> void:
	if (follow_target.get("_is_moving") != null and follow_target._is_moving):
		_moving_to_target = true
	if _moving_to_target:
		if _dz_to_target != fix_dz_to_target:
			_dz_to_target = fix_dz_to_target
		if _dx_to_target != 0.0:
			_dx_to_target = 0.0
		var target_pos = follow_target.global_position
		target_pos.x += _dx_to_target
		target_pos.z += _dz_to_target
		var my_target_pos = _get_my_pos_by(target_pos)
		var e = my_target_pos.distance_squared_to(global_position)
		if e < 0.001:
			_update_camera()
			_moving_to_target = false
			return
		else:
			global_position = global_position.lerp(my_target_pos, 0.02)
		
	
	#if _is_moving:
		#var rel := Input.get_last_mouse_velocity()
		#var dx = clampf(rel.x * move_sensitivity, -0.4, 0.4)
		#var dy = clampf(rel.y * move_sensitivity, -0.4, 0.4)
		#_dx_to_target += dx
		#_dz_to_target += dy
		#global_position = global_position - Vector3(dx, 0, dy)
		#_is_moving = false
	#elif _is_rotating:
		#var rel := Input.get_last_mouse_velocity()
		## _yaw   -= rel.x * sensitivity
		#_pitch -= rel.y * sensitivity
		#_pitch = clamp(_pitch, 0.23, 0.88)
		#if Game.Debug == 1:
			#print("yaw =", _yaw, ", pitch =", _pitch)
		#_update_camera()
	
	if ui_area_detector.is_mouse_inside:
		return

	var viewport := get_viewport()
	var viewport_rect := viewport.get_visible_rect()
	var viewport_size := viewport_rect.size
	var mouse_pos := viewport.get_mouse_position()
	if not viewport_rect.grow(15.0).has_point(mouse_pos): # 鼠标移出视口（且超出视口15.0）
		return
	var move_direction := Vector3.ZERO 
	
	# 检测屏幕边缘
	if mouse_pos.x < edge_threshold and _dx_to_target > -7.5:
		move_direction.x -= 1  # 向左移动
	elif mouse_pos.x > viewport_size.x - edge_threshold and _dx_to_target < 7.5:
		move_direction.x += 1  # 向右移动
	if mouse_pos.y < edge_threshold and _dz_to_target > -7.0:
		move_direction.z -= 1  # 向前移动
	elif mouse_pos.y > viewport_size.y - edge_threshold and _dz_to_target < 2.5:
		move_direction.z += 1  # 向后移动
	
	# 标准化移动方向并应用速度
	if move_direction.length() > 0:
		var mv = move_direction.normalized() * move_speed * delta
		_dx_to_target += mv.x
		_dz_to_target += mv.z
		# print(_dx_to_target, ",", _dz_to_target)
		_update_camera()

func _update_camera() -> void:
	var target = follow_target.global_position
	target.x = target.x + _dx_to_target
	target.z = target.z + _dz_to_target
	global_position = _get_my_pos_by(target)
	#look_at(follow_target.global_position, Vector3.UP)

# 聚焦到 p 时，相机的坐标
func _get_my_pos_by(p: Vector3) ->Vector3:
	var v := Vector3(
		dist_to_target * cos(_pitch) * sin(_yaw),
		dist_to_target * sin(_pitch),
		dist_to_target * cos(_pitch) * cos(_yaw)
	)
	return p + v
