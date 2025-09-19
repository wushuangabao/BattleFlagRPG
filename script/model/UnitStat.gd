# 管理单位的数据
class_name UnitStat extends AbstractModel

var _actor   : ActorController
var LV       : AttributeBase
var my_exp   : AttributeBase

# 基础属性
var base_attr : ActorBaseAttr

# 装备属性（临时用字典替代，等装备系统实现后替换）
var gear : Dictionary = {
	"HIT": 0.0,   # 命中
	"EVA": 0.0,   # 闪避
	"CR": 0.0,    # 暴击率
	"CD": 0.0,    # 暴击伤害
	"PAR": 0.0,   # 招架率
	"PDR": 0.0,   # 招架减伤
	"CTR": 0.0,   # 反击率
	"ATKp": 0.0,  # 物理攻击
	"ATKm": 0.0,  # 法术攻击
	"DEFp": 0.0,  # 物理防御
	"DEFm": 0.0,  # 法术防御
	"PenP": 0.0,  # 破甲
	"PenM": 0.0,  # 破气
	"RES": 0.0    # 异常抗性
}

# 战斗属性（根据基础属性、LV计算得来）
var HP       : AttributeBase
var MP       : AttributeBase
var ATKp     : BindableProperty
var ATKm     : BindableProperty
var DEFp     : BindableProperty
var DEFm     : BindableProperty
var HIT      : BindableProperty  # 命中率
var EVA      : BindableProperty  # 闪避率
var CR       : BindableProperty  # 暴击率
var CD       : BindableProperty  # 暴击伤害倍数
var PAR      : BindableProperty  # 招架/格挡率
var PDR      : BindableProperty  # 招架减伤
var CTR      : BindableProperty  # 反击率
var SPD      : BindableProperty  # 行动速度
var PENp     : BindableProperty  # 破甲
var PENm     : BindableProperty  # 破气
var RES      : BindableProperty  # 异常抗性

const BASE_HIT = 0.7
const MAX_HIT  = 1.1
const MAX_EVA  = 0.9

func init_by_db(actor_name: StringName) -> void:
	base_attr = ActorBaseAttr.new(_actor, actor_name)
	LV = AttributeBase.new(_actor, 1, Game.MAX_LEVEL)
	my_exp = AttributeBase.new(_actor, 0, 10000) # todo 读经验表
	init_all_by_base_attr()

func _init(a) -> void:
	_actor = a
	var has_save := false
	if has_save:
		return # todo 读档
	else: # 读数据表
		init_by_db(a.my_name)
	base_attr.register(on_base_attr_changed)

func on_init() -> void:
	HP.register(Game.g_combat.on_actor_hp_changed)
	HP.register(Game.g_actors.on_actor_hp_changed)
	MP.register(Game.g_combat.on_actor_mp_changed)
	MP.register(Game.g_actors.on_actor_mp_changed)

func on_base_attr_changed(attr_type: ActorBaseAttr.BaseAttrName, actor: ActorController, new_value: int, old_value: int) -> void:
	print("角色【", actor, "】的基础属性【", ActorBaseAttr.get_base_attr_name(attr_type), "】发生改变：", old_value, " -> ", new_value)
	update_all_by_base_attr()

func init_all_by_base_attr() -> void:
	HP   = AttributeBase.new(_actor, 0, calculate_hp())
	HP.fill()
	MP   = AttributeBase.new(_actor, 0, calculate_mp())
	MP.fill()
	SPD  = BindableProperty.new(calculate_spd_x())
	ATKp = BindableProperty.new(calculate_atk_p())
	ATKm = BindableProperty.new(calculate_atk_m())
	DEFp = BindableProperty.new(calculate_def_p())
	DEFm = BindableProperty.new(calculate_def_m())
	HIT  = BindableProperty.new(calculate_hit())
	EVA  = BindableProperty.new(calculate_eva())
	CR   = BindableProperty.new(calculate_cr())
	CD   = BindableProperty.new(calculate_cd())
	PAR  = BindableProperty.new(calculate_par())
	PDR  = BindableProperty.new(calculate_pdr())
	CTR  = BindableProperty.new(calculate_ctr())
	PENp = BindableProperty.new(calculate_pen_p())
	PENm = BindableProperty.new(calculate_pen_m())
	RES  = BindableProperty.new(calculate_res())

# 根据基础属性，计算并赋值所有战斗属性
func update_all_by_base_attr() -> void:
	HP.maximum = calculate_hp()
	MP.maximum = calculate_mp()
	SPD.value  = calculate_spd_x()
	ATKp.value = calculate_atk_p()
	ATKm.value = calculate_atk_m()
	DEFp.value = calculate_def_p()
	DEFm.value = calculate_def_m()
	HIT.value  = calculate_hit()
	EVA.value  = calculate_eva()
	CR.value   = calculate_cr()
	CD.value   = calculate_cd()
	PAR.value  = calculate_par()
	PDR.value  = calculate_pdr()
	CTR.value  = calculate_ctr()
	PENp.value = calculate_pen_p()
	PENm.value = calculate_pen_m()
	RES.value  = calculate_res()

func trans_base_attr_to(attr: String) -> float:
	var attr_x_list = Game.get_base_attrs() as Array
	var ret := 0.0
	for i in attr_x_list.size():
		var attr_x = attr_x_list[i] as Dictionary
		if attr_x.has(attr):
			ret += attr_x[attr] * base_attr.at(i)
	return ret

func calculate_hp() -> int:
	return 80 + 20 * LV.value + floori(trans_base_attr_to("HP"))
func calculate_mp() -> int:
	return 60 + 15 * LV.value + floori(trans_base_attr_to("MP"))

func calculate_spd_x() -> float:
	return 1.0 + trans_base_attr_to("SPD")

func calculate_atk_p() -> int:
	# BaseATKp = 15 + 5 × L
	var a : int = 15 + 5 * LV.value + floori(trans_base_attr_to("ATKp")) + floori(gear["ATKp"])
	if a > Game.MAX_ATK:
		return Game.MAX_ATK
	return a

func calculate_atk_m() -> int:
	# BaseATKm = 15 + 5 × L
	var a : int = 15 + 5 * LV.value + floori(trans_base_attr_to("ATKm")) + floori(gear["ATKm"])
	if a > Game.MAX_ATK:
		return Game.MAX_ATK
	return a

func calculate_def_p() -> int:
	# BaseDEFp = 8 + 3 × L
	var d : int = 8 + 3 * LV.value + floori(trans_base_attr_to("DEFp")) + floori(gear["DEFp"])
	if d > Game.MAX_DEF:
		return Game.MAX_DEF
	return d

func calculate_def_m() -> int:
	# BaseDEFm = 8 + 3 × L
	var d : int = 8 + 3 * LV.value + floori(trans_base_attr_to("DEFm")) + floori(gear["DEFm"])
	if d > Game.MAX_DEF:
		return Game.MAX_DEF
	return d

# 命中率计算：HIT = min[70% + f(基础属性)*0.4 + Gear.HIT, 110%]
func calculate_hit() -> float:
	var bonus_hit = trans_base_attr_to("HIT") * (MAX_HIT - BASE_HIT) + gear["HIT"]  # 数值设计需要把 HIT 控制在 100 以内
	return min(BASE_HIT + bonus_hit, MAX_HIT)  # 上限110%（额外40%）

# 闪避率计算：EVA = min[f(基础属性)*0.9 + Gear.EVA, 90%]
func calculate_eva() -> float:
	var total_eva = trans_base_attr_to("EVA") * MAX_EVA + gear["EVA"]  # 数值设计需要把 EVA 控制在 100 以内
	return min(total_eva, MAX_EVA)  # 上限90%

# 暴击率计算：CR = min[20% + f(基础属性) + Gear.CR, 80%]
func calculate_cr() -> float:
	var base_cr = 0.2
	var total_cr = base_cr + trans_base_attr_to("CR") * 0.6 + gear["CR"]  # 数值设计需要把 CR 控制在 100 以内
	return min(total_cr, 0.8)  # 上限80%（额外60%）

# 暴击伤害倍数计算：CD = 150% 基础 + f(基础属性) + Gear.CD
func calculate_cd() -> float:
	var base_cd = 1.5  # 150%基础
	var total_cd = base_cd + trans_base_attr_to("CD") * 0.01 + gear["CD"]  # 数值设计需要把 CD 控制在 100 以内
	return total_cd

# 招架率计算：PAR = min[f(基础属性) + Gear.PAR, 75%]
func calculate_par() -> float:
	var base_par = 0.15
	var total_par = base_par + trans_base_attr_to("PAR") * 0.6 + gear["PAR"]  # 数值设计需要把 PAR 控制在 100 以内
	return min(total_par, 0.75)  # 上限75%（额外60%）

# 招架减伤计算：PDR = min[40% 基础 + f(基础属性) + Gear.PDR, 80%]
func calculate_pdr() -> float:
	var base_pdr = 0.4  # 40%基础
	var total_pdr = base_pdr + trans_base_attr_to("PDR") * 0.4 + gear["PDR"]  # 数值设计需要把 PDR 控制在 100 以内
	return min(total_pdr, 0.8)  # 上限80%（额外40%）

# 反击率计算：CTR = min[f(基础属性) + Gear.CTR, 40%]
func calculate_ctr() -> float:
	var total_ctr = trans_base_attr_to("CTR") * 0.4 + gear["CTR"]  # 数值设计需要把 CTR 控制在 100 以内
	return min(total_ctr, 0.4)  # 上限40%

# 破甲计算：PenP = f(基础属性) + Gear.PenP
# 0-100：线性增长0%→80%；100+：收益递减趋近100%
func calculate_pen_p() -> float:
	var total_pen_p = trans_base_attr_to("PenP") + gear["PenP"]
	if total_pen_p <= 100.0:
		return (total_pen_p / 100.0) * 0.8
	else:
		var excess = total_pen_p - 100.0
		return 0.8 + 0.2 * (1.0 - 1.0 / (1.0 + excess / 100.0))

# 破气计算：PenM = f(基础属性) + Gear.PenM
# 0-100：线性增长0%→80%；100+：收益递减趋近100%
func calculate_pen_m() -> float:
	var total_pen_m = trans_base_attr_to("PenM") + gear["PenM"]
	if total_pen_m <= 100.0:
		return (total_pen_m / 100.0) * 0.8
	else:
		var excess = total_pen_m - 100.0
		return 0.8 + 0.2 * (1.0 - 1.0 / (1.0 + excess / 100.0))

# 异常抗性计算：RES = f(基础属性) + Gear.RES
# 0-100：线性增长0%→40%；100+：收益递减趋近50%
func calculate_res() -> float:
	var total_res = trans_base_attr_to("RES") + gear["RES"]
	if total_res <= 100.0:
		return (total_res / 100.0) * 0.4
	else:
		var excess = total_res - 100.0
		return 0.4 + 0.5 * (1.0 - 1.0 / (1.0 + excess / 100.0))
