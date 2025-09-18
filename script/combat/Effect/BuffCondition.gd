## Buff状态条件
## 
## 检查目标是否拥有特定的Buff状态
class_name BuffCondition extends ConditionBase

## 要检查的Buff标签
@export var buff_tags : Array[StringName] = []

## 检查模式：是否需要拥有所有标签（true）还是任意一个（false）
@export var require_all : bool = false

func _init():
	condition_type = ConditionType.HasBuff
	condition_name = "Buff状态条件"

## 检查Buff条件
func _check_condition(target: ActorController, _caster: ActorController, _context: Dictionary) -> bool:
	if not target or buff_tags.is_empty():
		return false
	
	if require_all:
		# 需要拥有所有指定的Buff标签
		for tag in buff_tags:
			if not target.has_tag([tag]):
				return false
		return true
	else:
		# 只需要拥有任意一个Buff标签
		for tag in buff_tags:
			if target.has_tag([tag]):
				return true
		return false