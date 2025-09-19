class_name Skill extends Resource

enum TargetRule {
	All, Enemy, Friendly
}

@export var target_rule : TargetRule

var id : int
@export var name : String
@export var icon : Texture2D
@export var tags : Array[StringName] # “刀法”, “外攻”
@export_multiline var desc : String

@export var cost : Dictionary[StringName, int]
@export var cool_down : float # 使用后隔几秒可以再次使用
@export var charges   : int   # 一场战斗中可以使用多少次

@export var cast_time : float # 需要等待多少秒后才生效
@export var area_range: SkillAreaShape # 技能的影响范围
@export var area_chose: SkillAreaShape # 目标的选择范围

@export var filters : Array[StringName] # 标签过滤（比如不可对隐身）

@export var effects : Array[EffectBase] # 按序执行效果，可插入条件判断
@export var caster_anim : StringName # 施法者的动画

var scaling # 伤害公式参数
var hit_formula # 命中公式引用（可在 resolver 中按标签选择）

## 根据技能的目标规则和过滤条件筛选有效目标
## 
## 此函数会根据技能的target_rule（目标规则）和filters（过滤标签）
## 从给定的目标列表中筛选出符合条件的目标
##
## @param targets: 待筛选的目标列表，包含所有可能的目标角色
## @param me: 施法者，用于判断敌友关系
## @return: 筛选后的有效目标列表
func filter_targets(targets: Array[ActorController], me: ActorController) -> Array[ActorController]:
	var filtered : Array[ActorController] = []
	for t in targets:
		var is_valid := true
		# 根据目标规则判断目标是否有效
		match target_rule:
			TargetRule.Enemy:  # 敌方目标：排除同队伍的角色
				if t.team_id == me.team_id:
					is_valid = false
			TargetRule.Friendly:  # 友方目标：排除不同队伍的角色
				if t.team_id != me.team_id:
					is_valid = false
			# TargetRule.All 不需要特殊处理，所有目标都有效
		
		# 如果目标通过了队伍检查，再检查是否被过滤标签排除
		# 如果目标拥有任何过滤标签，则被排除（例如：隐身、无敌等状态）
		if is_valid and not t.has_tag(filters):
			filtered.append(t)
	return filtered

## 执行技能的所有效果
## 
## 按序执行技能的effects数组中的所有效果，每个效果都会检查其条件
## 只有满足条件的效果才会被执行
##
## @param caster: 施法者
## @param targets: 目标列表
## @param context: 执行上下文，包含技能执行的相关信息
## @return: 所有效果的执行结果数组
func execute_effects(caster: ActorController, targets: Array[ActorController], context: Dictionary = {}) -> Array[Dictionary]:
	var results : Array[Dictionary] = []
	
	# 为每个目标执行所有效果
	for target in targets:
		for effect in effects:
			# 设置效果的施法者和目标
			effect.caster = caster
			effect.target = target
			
			# 检查效果的执行条件
			if effect.check_conditions(context):
				# 执行效果并收集结果
				var effect_result = effect.execute(context)
				
				# 添加基础信息到结果中
				effect_result["effect_name"] = effect.effect_name
				effect_result["effect_type"] = effect.my_type
				effect_result["target"] = target
				effect_result["caster"] = caster
				
				results.append(effect_result)
				
				# 如果效果执行失败，可以选择是否继续执行后续效果
				if effect_result.get("failed", false):
					print("效果执行失败: ", effect.effect_name)
					# 这里可以根据需要决定是否中断后续效果的执行
			else:
				# 条件不满足，记录跳过的效果
				print("效果条件不满足，跳过执行: ", effect.effect_name)
	
	return results

## 获取技能的预览信息
## 
## 返回技能及其所有效果的预览信息，用于UI显示
##
## @return: 包含技能预览信息的字典
func get_skill_preview() -> Dictionary:
	var preview = {
		"name": name,
		"description": "",  # 可以添加技能描述字段
		"cost": cost,
		"cool_down": cool_down,
		"charges": charges,
		"cast_time": cast_time,
		"tags": tags,
		"effects": []
	}
	
	# 添加所有效果的预览信息
	for effect in effects:
		preview.effects.append(effect.get_preview_info())
	
	return preview
