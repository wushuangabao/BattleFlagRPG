## 暴击条件
## 
## 检查当前攻击是否为暴击
class_name CriticalCondition extends ConditionBase

func _init():
	condition_type = ConditionType.IsCritical
	condition_name = "暴击条件"

## 检查暴击条件
func _check_condition(_target: ActorController, _caster: ActorController, context: Dictionary) -> bool:
	# 从上下文中获取是否暴击的信息
	return context.get("is_critical", false)