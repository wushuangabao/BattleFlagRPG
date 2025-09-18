## 血量阈值条件
## 
## 检查目标的血量是否满足指定的阈值条件
class_name HealthThresholdCondition extends ConditionBase

## 比较类型枚举
enum CompareType {
	LessThan,           # 小于
	LessOrEqual,        # 小于等于
	GreaterThan,        # 大于
	GreaterOrEqual,     # 大于等于
	Equal               # 等于
}

## 阈值（百分比，0.0-1.0）
@export var threshold : float = 0.5

## 比较类型
@export var compare_type : CompareType = CompareType.LessOrEqual

## 是否使用百分比（true）还是绝对值（false）
@export var use_percentage : bool = true

func _init():
	condition_type = ConditionType.HealthThreshold
	condition_name = "血量阈值条件"

## 检查血量条件
func _check_condition(target: ActorController, _caster: ActorController, _context: Dictionary) -> bool:
	if not target:
		return false
	
	var current_health = target.current_health
	var max_health = target.max_health
	
	var value_to_compare : float
	if use_percentage:
		value_to_compare = current_health / max_health if max_health > 0 else 0.0
	else:
		value_to_compare = current_health
	
	match compare_type:
		CompareType.LessThan:
			return value_to_compare < threshold
		CompareType.LessOrEqual:
			return value_to_compare <= threshold
		CompareType.GreaterThan:
			return value_to_compare > threshold
		CompareType.GreaterOrEqual:
			return value_to_compare >= threshold
		CompareType.Equal:
			return abs(value_to_compare - threshold) < 0.001  # 浮点数比较
	
	return false