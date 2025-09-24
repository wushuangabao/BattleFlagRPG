class_name Camera3D_movable extends Camera3D

#@export var move_sensitivity := 0.001      # 移动灵敏度
#@export var sensitivity      := 0.001      # 旋转灵敏度
@export var move_speed       := 10.0       # 镜头移动速度
@export var dist_to_target   := 15.0       # 相机到目标的距离（初始值）
@export var fix_to_target    := Vector2(0.5, 0.0)
@export var follow_target    : Node3D      # 跟随目标
@export var ui_area_detector : UI_Area_Detector

# 相机边界限制
var boundary_min : Vector3  # 相机位置最小边界
var boundary_max : Vector3    # 相机位置最大边界

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
	if not _moving_to_target and ui_area_detector.cursor_place != Vector2i.ZERO:
		var viewport := get_viewport()
		var viewport_rect := viewport.get_visible_rect()
		var mouse_pos := viewport.get_mouse_position()
		if viewport_rect.grow(15.0).has_point(mouse_pos): # 鼠标没有超出视口15.0
			var move_direction := Vector3(0, 0, 0)
			move_direction.x = ui_area_detector.cursor_place.x
			move_direction.z = ui_area_detector.cursor_place.y
			if move_direction.length() > 0.1:
				if _is_follow_target_moving:
					#print("相机：停止跟随目标移动")
					_is_follow_target_moving = false
					return
				var mv = move_direction.normalized() * move_speed * delta
				var new_position = global_position + mv
				
				# 检查边界限制
				new_position.x = clamp(new_position.x, boundary_min.x, boundary_max.x)
				new_position.z = clamp(new_position.z, boundary_min.z, boundary_max.z)
				
				global_position = new_position
				return
	if follow_target == null:
		return
	if _moving_to_target or _is_follow_target_moving:
		var target_pos = follow_target.global_position
		target_pos.x += fix_to_target.x
		target_pos.z += fix_to_target.y
		var my_target_pos = _get_my_pos_by(target_pos)
		
		# 检查边界限制
		my_target_pos.x = clamp(my_target_pos.x, boundary_min.x, boundary_max.x)
		my_target_pos.z = clamp(my_target_pos.z, boundary_min.z, boundary_max.z)
		
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
	target.x += fix_to_target.x
	target.z += fix_to_target.y
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

func set_boundary(dim: Vector2i, ground_y: float) -> void:
	var min_pos = Vector3(GroundLayer.BORDER_WIDTH * 1.5 * Game.cell_world_size.x,
	ground_y,
	GroundLayer.BORDER_WIDTH * Game.cell_world_size.y)

	var max_pos = Vector3((dim.x - GroundLayer.BORDER_WIDTH * 1.5) * Game.cell_world_size.x,
	ground_y,
	(dim.y - GroundLayer.BORDER_WIDTH) * Game.cell_world_size.y)

	boundary_min = _get_my_pos_by(min_pos)
	boundary_max = _get_my_pos_by(max_pos)
	
