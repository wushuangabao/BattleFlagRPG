## 位移效果
## 
## 对目标或施法者进行位移操作（推拉、突进、闪现等）
class_name MoveEffect extends EffectBase

## 位移类型枚举
enum MoveType {
	Push,           # 推开目标
	Pull,           # 拉近目标
	Dash,           # 施法者突进到目标
	Teleport,       # 瞬移到指定位置
	Knockback,      # 击退
	Swap            # 交换位置
}

## 位移类型
@export var move_type : MoveType = MoveType.Push

## 位移距离
@export var distance : float = 3.0

## 位移速度（单位/秒，0表示瞬间移动）
@export var move_speed : float = 10.0

## 是否影响施法者（true）还是目标（false）
@export var affects_caster : bool = false

## 位移方向（相对于施法者到目标的方向）
## 1.0 = 远离施法者，-1.0 = 靠近施法者，0.0 = 垂直方向
@export var direction_modifier : float = 1.0

## 是否检查碰撞
@export var check_collision : bool = true

## 是否可以穿越障碍物
@export var ignore_obstacles : bool = false

## 位移过程中是否造成伤害
@export var damage_during_move := 0

## 位移完成后的效果
@export var on_move_complete_effects : Array[EffectBase] = []

func _init():
	my_type = EffectType.Move
	effect_name = "位移效果"

## 执行位移效果
func execute(context: Dictionary = {}) -> Dictionary:
	var result = {
		"move_successful": false,
		"move_type": move_type,
		"distance_moved": 0.0,
		"start_position": Vector3.ZERO,
		"end_position": Vector3.ZERO,
		"collision_occurred": false
	}
	
	if not target or not caster:
		result["failed"] = true
		return result
	
	var mover = caster if affects_caster else target
	var refer = target if affects_caster else caster
	
	result["start_position"] = mover.global_position
	
	match move_type:
		MoveType.Push:
			execute_push_pull(mover, refer, distance, result)
		MoveType.Pull:
			execute_push_pull(mover, refer, -distance, result)
		MoveType.Dash:
			execute_dash(mover, refer, result)
		MoveType.Teleport:
			execute_teleport(mover, refer, result)
		MoveType.Knockback:
			execute_knockback(mover, refer, result)
		MoveType.Swap:
			execute_swap(mover, refer, result)
	
	# 执行位移完成后的效果
	if result["move_successful"] and not on_move_complete_effects.is_empty():
		for effect in on_move_complete_effects:
			effect.caster = caster
			effect.target = target
			effect.execute(context)
	
	return result

## 执行推拉效果
func execute_push_pull(mover: ActorController, refer: ActorController, move_distance: float, result: Dictionary):
	var direction = (mover.global_position - refer.global_position).normalized()
	direction *= direction_modifier
	
	var target_position = mover.global_position + direction * move_distance
	
	if check_collision and not ignore_obstacles:
		target_position = check_valid_position(mover, target_position)
	
	var actual_distance = mover.global_position.distance_to(target_position)
	
	if move_speed > 0:
		# 平滑移动
		mover.move_to_position(target_position, move_speed)
	else:
		# 瞬间移动
		mover.set_position(target_position)
	
	result["move_successful"] = true
	result["distance_moved"] = actual_distance
	result["end_position"] = target_position

## 执行突进效果
func execute_dash(mover: ActorController, refer: ActorController, result: Dictionary):
	var direction = (refer.global_position - mover.global_position).normalized()
	var target_position = refer.global_position - direction * 1.0  # 在目标前1单位停下
	
	if check_collision and not ignore_obstacles:
		target_position = check_valid_position(mover, target_position)
	
	var actual_distance = mover.global_position.distance_to(target_position)
	
	if move_speed > 0:
		mover.move_to_position(target_position, move_speed)
	else:
		mover.set_position(target_position)
	
	# 突进过程中造成伤害
	if damage_during_move > 0:
		refer.take_damage(damage_during_move, mover)
	
	result["move_successful"] = true
	result["distance_moved"] = actual_distance
	result["end_position"] = target_position

## 执行瞬移效果
func execute_teleport(mover: ActorController, refer: ActorController, result: Dictionary):
	var target_position = refer.global_position
	
	# 瞬移通常忽略障碍物，但仍需检查目标位置是否有效
	if check_collision:
		target_position = check_valid_position(mover, target_position)
	
	var actual_distance = mover.global_position.distance_to(target_position)
	mover.set_position(target_position)
	
	result["move_successful"] = true
	result["distance_moved"] = actual_distance
	result["end_position"] = target_position

## 执行击退效果
func execute_knockback(mover: ActorController, refer: ActorController, result: Dictionary):
	# 击退类似推开，但通常有更强的效果
	execute_push_pull(mover, refer, distance * 1.5, result)

## 执行位置交换
func execute_swap(mover: ActorController, refer: ActorController, result: Dictionary):
	var mover_pos = mover.global_position
	var reference_pos = refer.global_position
	
	mover.set_position(reference_pos)
	refer.set_position(mover_pos)
	
	result["move_successful"] = true
	result["distance_moved"] = mover_pos.distance_to(reference_pos)
	result["end_position"] = reference_pos

## 检查位置是否有效
func check_valid_position(mover: ActorController, target_position: Vector3) -> Vector3:
	# 这里需要根据游戏的碰撞检测系统来实现
	# 暂时返回原始位置，具体实现需要依赖游戏的空间管理系统
	return target_position