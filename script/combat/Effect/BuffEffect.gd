## Buff效果
## 
## 给目标施加状态效果（增益或减益）
class_name BuffEffect extends EffectBase

## Buff类型枚举
enum BuffType {
	Beneficial,    # 增益效果
	Debuff,        # 减益效果
	Neutral        # 中性效果
}

## Buff的ID或名称
@export var buff_id : String = ""

## Buff类型
@export var buff_type : BuffType = BuffType.Beneficial

## 持续时间（秒，-1表示永久）
@export var duration : float = 10.0

## 叠加层数
@export var stack_count : int = 1

## 最大叠加层数
@export var max_stacks : int = 1

## 是否可以刷新持续时间
@export var can_refresh : bool = true

## 是否可以被驱散
@export var can_be_dispelled : bool = true

## Buff标签（用于分类和驱散）
@export var buff_tags : Array[StringName] = []

## 属性修改（例如 {"attack": 50, "defense": -20}）
@export var attribute_modifiers : Dictionary = {}

## 周期性效果的间隔时间（0表示无周期性效果）
@export var tick_interval : float = 0.0

## 周期性效果的数据
@export var tick_effects : Array[EffectBase] = []

func _init():
	my_type = EffectType.AddBuff
	effect_name = "Buff效果"

## 执行Buff效果
func execute(context: Dictionary = {}) -> Dictionary:
	var result = {
		"buff_applied": false,
		"buff_id": buff_id,
		"duration": duration,
		"stacks_applied": 0,
		"existing_stacks": 0
	}
	
	if not target or buff_id.is_empty():
		result["failed"] = true
		return result
	
	# 检查目标是否已经有这个Buff
	var existing_buff = target.get_buff(buff_id)
	
	if existing_buff:
		# 已存在的Buff处理
		handle_existing_buff(existing_buff, result)
	else:
		# 新Buff处理
		apply_new_buff(result)
	
	return result

## 处理已存在的Buff
func handle_existing_buff(existing_buff, result: Dictionary):
	var current_stacks = existing_buff.get("stacks", 1)
	
	if current_stacks < max_stacks:
		# 可以继续叠加
		var new_stacks = min(current_stacks + stack_count, max_stacks)
		var stacks_added = new_stacks - current_stacks
		
		target.update_buff_stacks(buff_id, new_stacks)
		result["stacks_applied"] = stacks_added
		result["existing_stacks"] = current_stacks
		result["buff_applied"] = true
		
		# 刷新持续时间
		if can_refresh:
			target.refresh_buff_duration(buff_id, duration)
	else:
		# 已达到最大层数
		if can_refresh:
			target.refresh_buff_duration(buff_id, duration)
		result["existing_stacks"] = current_stacks
		result["buff_applied"] = false

## 应用新Buff
func apply_new_buff(result: Dictionary):
	var buff_data = create_buff_data()
	
	if target.add_buff(buff_data):
		result["buff_applied"] = true
		result["stacks_applied"] = stack_count
		result["existing_stacks"] = 0
	else:
		result["failed"] = true

## 创建Buff数据
func create_buff_data() -> Dictionary:
	return {
		"id": buff_id,
		"name": effect_name,
		"type": buff_type,
		"duration": duration,
		"stacks": stack_count,
		"max_stacks": max_stacks,
		"can_refresh": can_refresh,
		"can_be_dispelled": can_be_dispelled,
		"tags": buff_tags,
		"attribute_modifiers": attribute_modifiers,
		"tick_interval": tick_interval,
		"tick_effects": tick_effects,
		"caster": caster,
		"source_effect": self
	}
