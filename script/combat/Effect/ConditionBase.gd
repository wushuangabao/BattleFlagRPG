## 效果执行条件基类
## 
## 用于判断效果是否应该执行的条件系统
## 所有具体的条件类型都应该继承此基类并实现is_satisfied方法
class_name ConditionBase extends Resource

## 条件类型枚举
enum ConditionType {
	HealthThreshold,    # 血量阈值条件
	IsCritical,         # 是否暴击条件
	IsHit,              # 是否命中条件
	HasBuff,            # 是否有特定Buff条件
	TeamCheck,          # 队伍检查条件
	DistanceCheck,      # 距离检查条件
	ResourceCheck,      # 资源检查条件（MP/AP等）
	Custom              # 自定义条件
}

## 条件类型
@export var condition_type : ConditionType

## 条件名称（用于调试）
@export var condition_name : String = ""

## 是否反转条件结果
@export var invert : bool = false

## 检查条件是否满足的虚拟方法
## @param target: 目标角色
## @param caster: 施法者
## @param context: 执行上下文
## @return: 条件是否满足
func is_satisfied(target: ActorController, caster: ActorController, context: Dictionary) -> bool:
	var result = _check_condition(target, caster, context)
	return result if not invert else not result

## 具体的条件检查逻辑，子类需要重写此方法
## @param target: 目标角色
## @param caster: 施法者
## @param context: 执行上下文
## @return: 条件是否满足
func _check_condition(_target: ActorController, _caster: ActorController, _context: Dictionary) -> bool:
	push_error("ConditionBase._check_condition() must be overridden in subclass")
	return false