## 伤害效果
## 
## 对目标造成伤害，支持多段伤害和溅射效果
class_name DamageEffect extends EffectBase

## 伤害类型
@export var damage_type : Resolver.DamageType = Resolver.DamageType.Physical

## 伤害段数（多段伤害）
@export var hit_count : int = 1

## 每段伤害的间隔时间（秒）
@export var hit_interval : float = 0.3

## 是否有溅射效果
@export var has_splash : bool = false

## 溅射范围（如果有溅射）
@export var splash_range : float = 1.0

## 溅射伤害衰减比例
@export_range(0.0, 1.0) var splash_damage_ratio : float = 0.5

## 技能威力系数
@export_range(0.8, 2.5) var power_coefficient : float = 1.0

## 技能熟练度加成（运行时设置）
var skill_bonus : float = 0.0


func _init():
	my_type = EffectType.Damage
	effect_name = "伤害效果"

## 执行伤害效果
func execute(_context: Dictionary = {}) -> Dictionary:
	var result = {
		"actual_damage": 0.0,
		"is_critical": false,
		"is_hit": false,
		"hit_count": hit_count,
		"damage_type": damage_type,
		"splash_targets": []
	}
	
	if not target or not caster:
		result["failed"] = true
		return result
	
	# 使用Resolver进行完整的伤害计算
	var damage_result = Resolver.calculate_damage(caster, target, damage_type, power_coefficient, skill_bonus)
	
	result["is_hit"] = damage_result["hit"]
	result["is_critical"] = damage_result["critical"]
	
	if not damage_result["hit"]:
		# 未命中，直接返回
		return result
	
	var final_damage = damage_result["damage"]
	
	# 应用伤害到目标
	var actual_damage = apply_damage_to_target(final_damage)
	result["actual_damage"] = actual_damage
	
	# 处理溅射效果
	if has_splash:
		var splash_targets = get_splash_targets()
		for splash_target in splash_targets:
			# 溅射伤害也使用相同的计算逻辑，但伤害减少
			var splash_result = Resolver.calculate_damage(caster, splash_target, damage_type, power_coefficient * splash_damage_ratio, skill_bonus)
			if splash_result["hit"]:
				var splash_actual = apply_damage_to_target(splash_result["damage"], splash_target)
				result.splash_targets.append({
					"target": splash_target,
					"damage": splash_actual,
					"is_critical": splash_result["critical"]
				})
	return result

## 对目标应用伤害
func apply_damage_to_target(damage: float, damage_target: ActorController = null) -> float:
	var actual_target = damage_target if damage_target else target
	
	# 伤害计算已经在Resolver中完成，这里直接应用
	var final_damage = max(1.0, damage)  # 确保至少造成1点伤害
	
	# 应用伤害到目标
	actual_target.take_damage(final_damage, caster)
	
	return final_damage

## 获取溅射目标
func get_splash_targets() -> Array[ActorController]:
	var splash_targets : Array[ActorController] = []
	
	# 这里需要根据游戏的空间系统来查找范围内的目标
	# 暂时返回空数组，具体实现需要依赖游戏的空间管理系统
	
	return splash_targets