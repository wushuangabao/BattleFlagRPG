class_name Resolver

# 负责检定命中 → 暴击 → 伤害 → 应用Effect列表
# 标签系统贯穿：单位、技能、效果、Buff、武器都带 tags，resolver 可基于 tags 注入特判（例如“对中毒目标+20%伤害”）

## 伤害类型枚举
enum DamageType {
	Physical,    # 外功伤害
	Magical,     # 内功伤害
	True,        # 真实伤害（无视防御）
}

## 检定命中
## @param attacker: 攻击者
## @param target: 目标
## @return: 是否命中
static func check_hit(attacker: ActorController, target: ActorController) -> bool:
	if not attacker or not target:
		return false
	var attacker_hit = attacker.my_stat.HIT.value
	var target_eva = target.my_stat.EVA.value
	var hit_chance = clampf(calclulate_hit_chance(attacker_hit, target_eva), 0.05, 0.99)
	return PseudoRandom.chance(hit_chance)

## 使用软上限差值计算真实命中率
static func calclulate_hit_chance(attacker_hit: float, target_eva: float) -> float:
	# 归一化面板值到 [0,1]
	var a = (attacker_hit - UnitStat.BASE_HIT) / (UnitStat.MAX_HIT - UnitStat.BASE_HIT)  # 命中：[70%, 110%] → [0, 1]
	var d = target_eva / UnitStat.MAX_EVA  # 闪避：[0%, 90%] → [0, 1]
	
	return UnitStat.BASE_HIT + 0.4 * a - 0.63 * d

## 检定暴击
## @param attacker: 攻击者
## @param target: 目标
## @return: 是否暴击
static func check_critical(attacker: ActorController, target: ActorController) -> bool:
	if not attacker or not target:
		return false
	
	var critical_rate = attacker.my_stat.CR.value
	return PseudoRandom.chance(critical_rate)

## 计算外功伤害
## @param attacker: 攻击者
## @param target: 目标
## @param pow_coef: 技能威力系数（0.8-2.5）
## @param skill_bonus: 技能熟练度加成（0-1+）
## @param is_critical: 是否暴击
## @return: 最终伤害值
static func calculate_physical_damage(attacker: ActorController, target: ActorController, pow_coef: float, skill_bonus: float, is_critical: bool) -> float:
	if not attacker or not target:
		return 0.0
	
	# 原始伤害 RawP = ATKp × PowCoef × [1 + Skill%]
	var raw_damage = attacker.my_stat.ATKp.value * pow_coef * (1.0 + skill_bonus)
	
	# 有效防御 EDEFp = DEFp × (1 − PenP% − Debuff防降)
	var pen_p = attacker.my_stat.PENp.value
	var debuff_def_reduction = 0.0  # TODO: 从Buff系统获取防御降低效果
	var effective_defense = target.my_stat.DEFp.value * (1.0 - pen_p - debuff_def_reduction)
	effective_defense = max(0.0, effective_defense)  # 防御不能为负
	
	# 净伤害 Phy = RawP × Mitigate( EDEFp , L )
	var level = target.my_stat.LV.value
	var mitigation = calculate_mitigation(effective_defense, level)
	var final_damage = raw_damage * mitigation
	
	# 暴击伤害
	if is_critical:
		var critical_multiplier = attacker.my_stat.CD.value
		final_damage *= critical_multiplier
	
	return max(1.0, final_damage)  # 最少造成1点伤害

## 计算内功伤害
## @param attacker: 攻击者
## @param target: 目标
## @param pow_coef: 技能威力系数（0.8-2.5）
## @param skill_bonus: 技能熟练度加成（0-1+）
## @param is_critical: 是否暴击
## @return: 最终伤害值
static func calculate_magical_damage(attacker: ActorController, target: ActorController, pow_coef: float, skill_bonus: float, is_critical: bool) -> float:
	if not attacker or not target:
		return 0.0
	
	# 原始伤害 RawM = ATKm × PowCoef × [1 + Skill%]
	var raw_damage = attacker.my_stat.ATKm.value * pow_coef * (1.0 + skill_bonus)
	
	# 有效防御 EDEFm = DEFm × (1 − PenM% − Debuff防降)
	var pen_m = attacker.my_stat.PENm.value
	var debuff_def_reduction = 0.0  # TODO: 从Buff系统获取防御降低效果
	var effective_defense = target.my_stat.DEFm.value * (1.0 - pen_m - debuff_def_reduction)
	effective_defense = max(0.0, effective_defense)  # 防御不能为负
	
	# 净伤害 Mag = RawM × Mitigate( EDEFm , L )
	var level = target.my_stat.LV.value
	var mitigation = calculate_mitigation(effective_defense, level)
	var final_damage = raw_damage * mitigation
	
	# 暴击伤害
	if is_critical:
		var critical_multiplier = attacker.my_stat.CD.value
		final_damage *= critical_multiplier
	
	return max(1.0, final_damage)  # 最少造成1点伤害

## 计算减伤公式
## Mitigate(d, L) = 1 − d / (d + 50 + 5L)
## @param defense: 有效防御值
## @param level: 目标等级
## @return: 减伤系数（0-1）
static func calculate_mitigation(defense: float, level: int) -> float:
	return 1.0 - defense / (defense + 50.0 + 5.0 * level)

## 完整的伤害计算流程
## @param attacker: 攻击者
## @param target: 目标
## @param damage_type: 伤害类型
## @param pow_coef: 技能威力系数
## @param skill_bonus: 技能熟练度加成
## @return: 伤害计算结果字典
static func calculate_damage(attacker: ActorController, target: ActorController, damage_type: DamageType, pow_coef: float, skill_bonus: float) -> Dictionary:
	var result = {
		"hit": false,
		"critical": false,
		"damage": 0.0,
		"damage_type": damage_type
	}
	
	if not attacker or not target:
		return result
	
	# 1. 命中检定
	var hit = check_hit(attacker, target)
	result["hit"] = hit
	
	if not hit:
		return result  # 未命中，直接返回
	
	# 2. 暴击检定
	var critical = check_critical(attacker, target)
	result["critical"] = critical
	
	# 3. 伤害计算
	var damage = 0.0
	match damage_type:
		DamageType.Physical:
			damage = calculate_physical_damage(attacker, target, pow_coef, skill_bonus, critical)
		DamageType.Magical:
			damage = calculate_magical_damage(attacker, target, pow_coef, skill_bonus, critical)
		DamageType.True:
			# 真实伤害：基础伤害 × 威力系数 × 技能加成
			damage = attacker.my_stat.ATKp.value * pow_coef * (1.0 + skill_bonus)
			if critical:
				damage *= attacker.my_stat.CD.value
	
	result["damage"] = damage
	return result
