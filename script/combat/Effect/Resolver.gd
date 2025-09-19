class_name Resolver

# 负责检定命中 → 暴击 → 伤害 → 应用Effect列表
# 标签系统贯穿：单位、技能、效果、Buff、武器都带 tags，resolver 可基于 tags 注入特判（例如“对中毒目标+20%伤害”）

## 伤害类型枚举
enum DamageType {
	Physical,    # 外功伤害
	Magical,     # 内功伤害
}

## 计算攻击角度对防御能力的影响系数
## @param attacker: 攻击者
## @param target: 目标
## @param is_defend: 目标是否处于防御状态
## @return: 防御能力系数
static func calculate_angle_bonus(attacker: ActorController, target: ActorController, is_defend: bool) -> float:
	if not attacker or not target or not attacker.base3d or not target.base3d:
		return 1.0
	
	# 获取攻击者和目标的位置
	var attacker_pos := attacker.base3d.get_cur_cell()
	var target_pos := target.base3d.get_cur_cell()
	
	# 计算攻击方向向量
	var attack_dir := attacker_pos - target_pos
	if attack_dir == Vector2i.ZERO:
		return 1.0  # 同一位置，无角度影响
	
	# 获取目标的背面法线方向
	var target_facing := target.get_facing_vector()
	var target_back_normal := -target_facing
	
	# 计算攻击方向与目标背面法线的夹角
	var angle := MathUtils.angle_between(attack_dir, target_back_normal)
	
	# 使用绝对角度值进行判断，因为angle_to返回的范围是[-PI, PI]
	var abs_angle := absf(angle)
	
	# 根据角度和防御状态返回系数
	if abs_angle + 0.01 < Game.pi_4:         # 背袭（0°~45°）
		print("背袭角度：", abs_angle * 180 / PI)
		return 0.5 if is_defend else 0.25
	elif abs_angle + 0.01 < Game.pi_2:       # 侧面攻击（45°~90°）
		print("侧后方攻击角度：", abs_angle * 180 / PI)
		return 0.75 if is_defend else 0.5
	elif abs(abs_angle - Game.pi_2) < 0.011:  # 正侧面（90°）
		print("侧面攻击角度：", abs_angle * 180 / PI)
		return 1.0 if is_defend else 0.75
	else:                                 # 正面，范围90°~180°
		print("正面攻击角度：", abs_angle * 180 / PI)
		return 1.25 if is_defend else 1.0

## 检定命中
## @param attacker: 攻击者
## @param target: 目标
## @return: 是否命中
static func check_hit(attacker: ActorController, target: ActorController, state_bonus: float) -> bool:
	var attacker_hit = attacker.my_stat.HIT.value
	var target_eva = target.my_stat.EVA.value * state_bonus
	var hit_chance = clampf(calclulate_hit_chance(attacker_hit, target_eva), 0.05, 0.99)
	return PseudoRandom.chance(hit_chance)

## 计算真实命中率（可以使用 AttributeViewer 插件查看）
static func calclulate_hit_chance(attacker_hit: float, target_eva: float) -> float:
	# 归一化面板值到 [0,1]
	var a = (attacker_hit - UnitStat.BASE_HIT) / (UnitStat.MAX_HIT - UnitStat.BASE_HIT)  # 命中：[70%, 110%] → [0, 1]
	var d = target_eva / UnitStat.MAX_EVA  # 闪避：[0%, 180%] → [0, 2]
	
	return UnitStat.BASE_HIT + 0.4 * a - 0.63 * d

## 检定招架（格挡）
## @param attacker: 攻击者
## @param target: 目标
## @return: 是否招架成功
static func check_parry(_attacker: ActorController, target: ActorController, state_bonus: float) -> bool:
	var parry_rate = target.my_stat.PAR.value * state_bonus
	return PseudoRandom.chance(parry_rate)

## 检定反击
## @param attacker: 攻击者
## @param target: 目标
## @return: 是否反击成功
static func check_counter(_attacker: ActorController, target: ActorController, state_bonus: float) -> bool:
	var counter_rate = target.my_stat.CTR.value * state_bonus
	return PseudoRandom.chance(counter_rate)

## 检定暴击
## @param attacker: 攻击者
## @param target: 目标
## @return: 是否暴击
static func check_critical(attacker: ActorController, _target: ActorController) -> bool:
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
		"parry": false,
		"counter": false,
		"damage": 0.0
	}
	
	if not attacker or not target:
		return result
	
	# 计算攻击角度对防御能力的影响
	var is_defend = target.get_state() == ActorController.ActorState.Defend
	var state_bonus = calculate_angle_bonus(attacker, target, is_defend)
	
	# 1. 命中检定
	var hit = check_hit(attacker, target, state_bonus)
	result["hit"] = hit

	# 2. 反击检定
	var counter = check_counter(attacker, target, state_bonus)
	result["counter"] = counter
	
	if not hit:
		return result  # 未命中，直接返回
	
	# 3. 招架检定
	var parry = check_parry(attacker, target, state_bonus)
	result["parry"] = parry
	
	# 4. 暴击检定
	var critical = check_critical(attacker, target)
	result["critical"] = critical
	
	# 5. 伤害计算
	var damage = 0.0
	match damage_type:
		DamageType.Physical:
			damage = calculate_physical_damage(attacker, target, pow_coef, skill_bonus, critical)
		DamageType.Magical:
			damage = calculate_magical_damage(attacker, target, pow_coef, skill_bonus, critical)
	
	# 6. 应用减伤（如果招架成功）
	if parry:
		var parry_reduction = target.my_stat.PDR.value
		damage *= (1.0 - parry_reduction)
	
	result["damage"] = damage
	return result
