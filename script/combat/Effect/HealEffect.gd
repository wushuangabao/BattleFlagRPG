## 治疗效果
## 
## 恢复目标的生命值
class_name HealEffect extends EffectBase

## 治疗类型枚举
enum HealType {
	Instant,        # 瞬间治疗
	OverTime,       # 持续治疗
	Percentage      # 百分比治疗
}

## 基础治疗量
@export var base_heal : float = 100.0

## 治疗类型
@export var heal_type : HealType = HealType.Instant

## 持续时间（仅对OverTime类型有效）
@export var duration : float = 5.0

## 治疗间隔（仅对OverTime类型有效）
@export var tick_interval : float = 1.0

## 百分比治疗值（仅对Percentage类型有效，0.0-1.0）
@export var heal_percentage : float = 0.5

## 属性加成系数（基于施法者属性）
@export var attribute_scaling : Dictionary = {}  # 例如 {"magic_power": 1.0, "wisdom": 0.3}

## 是否可以超过最大生命值
@export var can_overheal : bool = false

## 超量治疗转化为护盾的比例（0.0-1.0）
@export var overheal_to_shield_ratio : float = 0.0

func _init():
	my_type = EffectType.Heal
	effect_name = "治疗效果"

## 执行治疗效果
func execute(context: Dictionary = {}) -> Dictionary:
	var result = {
		"heal_amount": 0.0,
		"overheal_amount": 0.0,
		"shield_gained": 0.0,
		"heal_type": heal_type
	}
	
	if not target or not caster:
		result["failed"] = true
		return result
	
	match heal_type:
		HealType.Instant:
			apply_instant_heal(result)
		HealType.OverTime:
			apply_heal_over_time(result)
		HealType.Percentage:
			apply_percentage_heal(result)
	
	return result

## 应用瞬间治疗
func apply_instant_heal(result: Dictionary):
	var heal_amount = calculate_heal_amount()
	var actual_heal = apply_heal_to_target(heal_amount)
	
	result["heal_amount"] = actual_heal["heal"]
	result["overheal_amount"] = actual_heal["overheal"]
	result["shield_gained"] = actual_heal["shield"]

## 应用持续治疗
func apply_heal_over_time(result: Dictionary):
	# 持续治疗需要创建一个Buff来处理
	# 这里先计算总治疗量，实际实现时应该创建一个HoT Buff
	var total_ticks = duration / tick_interval
	var heal_per_tick = calculate_heal_amount() / total_ticks
	
	# 暂时只应用第一次治疗，完整实现需要Buff系统
	var actual_heal = apply_heal_to_target(heal_per_tick)
	
	result["heal_amount"] = actual_heal["heal"]
	result["overheal_amount"] = actual_heal["overheal"]
	result["shield_gained"] = actual_heal["shield"]
	result["total_ticks"] = total_ticks
	result["heal_per_tick"] = heal_per_tick

## 应用百分比治疗
func apply_percentage_heal(result: Dictionary):
	var max_health = target.get_attribute("max_health")
	var heal_amount = max_health * heal_percentage
	
	# 应用属性加成
	for attr_name in attribute_scaling:
		var scaling_value = attribute_scaling[attr_name]
		var attr_value = caster.get_attribute(attr_name)
		heal_amount += attr_value * scaling_value
	
	var actual_heal = apply_heal_to_target(heal_amount)
	
	result["heal_amount"] = actual_heal["heal"]
	result["overheal_amount"] = actual_heal["overheal"]
	result["shield_gained"] = actual_heal["shield"]

## 计算治疗量
func calculate_heal_amount() -> float:
	var heal = base_heal
	
	# 根据施法者属性进行加成
	for attr_name in attribute_scaling:
		var scaling_value = attribute_scaling[attr_name]
		var attr_value = caster.get_attribute(attr_name)
		heal += attr_value * scaling_value
	
	return heal

## 对目标应用治疗
func apply_heal_to_target(heal_amount: float) -> Dictionary:
	var current_health = target.get_attribute("current_health")
	var max_health = target.get_attribute("max_health")
	
	var actual_heal = 0.0
	var overheal = 0.0
	var shield_gained = 0.0
	
	if can_overheal:
		# 可以超量治疗
		actual_heal = heal_amount
		target.heal(heal_amount)
	else:
		# 不能超过最大生命值
		var missing_health = max_health - current_health
		actual_heal = min(heal_amount, missing_health)
		overheal = heal_amount - actual_heal
		
		target.heal(actual_heal)
		
		# 超量治疗转化为护盾
		if overheal > 0 and overheal_to_shield_ratio > 0:
			shield_gained = overheal * overheal_to_shield_ratio
			target.add_shield(shield_gained)
	
	return {
		"heal": actual_heal,
		"overheal": overheal,
		"shield": shield_gained
	}