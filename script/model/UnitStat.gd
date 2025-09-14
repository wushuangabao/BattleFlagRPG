# 管理单位的数据
class_name UnitStat extends AbstractModel

var _actor   : ActorController
var LV       : AttributeBase
var my_exp   : AttributeBase

# 基础属性
var base_attr : ActorBaseAttr

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
	MP   = AttributeBase.new(_actor, 0, calculate_hp())
	MP.fill()
	SPD  = BindableProperty.new(calculate_spd_x())
	ATKp = BindableProperty.new(calculate_atk_p())
	ATKm = BindableProperty.new(calculate_atk_m())
	DEFp = BindableProperty.new(calculate_def_p())
	DEFm = BindableProperty.new(calculate_def_m())
	HIT  = BindableProperty.new(0.0)
	EVA  = BindableProperty.new(0.0)
	CR   = BindableProperty.new(0.0)
	CD   = BindableProperty.new(0.0)
	PAR  = BindableProperty.new(0.0)
	PDR  = BindableProperty.new(0.0)
	CTR  = BindableProperty.new(0.0)
	PENp = BindableProperty.new(0.0)
	PENm = BindableProperty.new(0.0)
	RES  = BindableProperty.new(0.0)

# 根据基础属性，计算并赋值所有战斗属性
func update_all_by_base_attr() -> void:
	HP.value   = calculate_hp()
	MP.value   = calculate_mp()
	SPD.value  = calculate_spd_x()
	ATKp.value = calculate_atk_p()
	ATKm.value = calculate_atk_m()
	DEFp.value = calculate_def_p()
	DEFm.value = calculate_def_m()
	# HIT.value  = calculate_hp()
	# EVA.value  = calculate_hp()
	# CR.value   = calculate_hp()
	# CD.value   = calculate_hp()
	# PAR.value  = calculate_hp()
	# PDR.value  = calculate_hp()
	# CTR.value  = calculate_hp()
	# PENp.value = calculate_hp()
	# PENm.value = calculate_hp()
	# RES.value  = calculate_hp()

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
	var a : int = 15 + 5 * LV.value + floori(trans_base_attr_to("Atkp"))
	if a > Game.MAX_ATK:
		return Game.MAX_ATK
	return a
func calculate_atk_m() -> int:
	var a : int = 15 + 5 * LV.value + floori(trans_base_attr_to("Atkm"))
	if a > Game.MAX_ATK:
		return Game.MAX_ATK
	return a

func calculate_def_p() -> int:
	var d : int = 8 + 3 * LV.value + floori(trans_base_attr_to("Defp"))
	if d > Game.MAX_DEF:
		return Game.MAX_DEF
	return d
func calculate_def_m() -> int:
	var d : int = 8 + 3 * LV.value + floori(trans_base_attr_to("Defm"))
	if d > Game.MAX_DEF:
		return Game.MAX_DEF
	return d
