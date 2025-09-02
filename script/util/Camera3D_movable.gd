extends Camera3D

@export var move_sensitivity := 0.001      # 移动灵敏度
@export var sensitivity      := 0.001      # 旋转灵敏度
@export var follow_target    : Node3D      # 跟随目标
@export var dist_to_target   := 10.0        # 相机到目标的距离（初始值）

# 到 follow_target 的偏移向量
var _dx_to_target := 0.0
var _dz_to_target := 0.0

# 当前极坐标（水平角 yaw，垂直角 pitch）
var _yaw   := 0.0
var _pitch := 0.9

var _is_moving   := false
var _is_rotating := false

func _unhandled_input(event: InputEvent) -> void:
	# 开始拖拽
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_is_moving = true
				
			else:
				_is_moving = false
			get_viewport().set_input_as_handled() #标记输入事件为已处理

func _process(delta) -> void:
	if follow_target.get("_is_moving") != null and follow_target._is_moving:
		global_position = global_position.lerp(_get_my_pos_by(follow_target.global_position), clampf(delta, 0.03, 0.3))
		return
		
	if _is_moving:
		var rel := Input.get_last_mouse_velocity()
		var dx = rel.x * move_sensitivity
		var dy = rel.y * move_sensitivity
		_dx_to_target += dx
		_dz_to_target += dy
		global_position = global_position + Vector3(dx, 0, dy)
		if Game.Debug == 1:
			print("camera ", global_position.x, ", ", global_position.y, ", ", global_position.z)
	elif _is_rotating:
		var rel := Input.get_last_mouse_velocity()
		# _yaw   -= rel.x * sensitivity
		_pitch -= rel.y * sensitivity
		_pitch = clamp(_pitch, 0.23, 0.88)
		if Game.Debug == 1:
			print("yaw =", _yaw, ", pitch =", _pitch)
		_update_camera()

func _update_camera() -> void:
	var target = follow_target.global_position
	target.x = target.x + _dx_to_target
	target.z = target.z + _dz_to_target
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

func _ready() -> void:
	_update_camera()
