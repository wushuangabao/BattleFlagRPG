# 管理单位的数据
class_name UnitStat extends AbstractModel

var _actor   :  ActorController
var base_attr : ActorBaseAttr  # 基础属性
var LV       := AttributeBase.new()
var my_exp   := AttributeBase.new()
var HP       := AttributeBase.new()
var MP       := AttributeBase.new()
var ATKp     := BindableProperty.new()
var ATKm     := BindableProperty.new()
var DEFp     := BindableProperty.new()
var DEFm     := BindableProperty.new()
var HIT      := BindableProperty.new()  # 命中率
var EVA      := BindableProperty.new()  # 闪避率
var CR       := BindableProperty.new()  # 暴击率
var CD       := BindableProperty.new()  # 暴击伤害倍数
var PAR      := BindableProperty.new()  # 招架/格挡率
var PDR      := BindableProperty.new()  # 招架减伤
var CTR      := BindableProperty.new()  # 反击率
var SPD      := BindableProperty.new()  # 行动速度
var PENp     := BindableProperty.new()  # 破甲
var PENm     := BindableProperty.new()  # 破气
var RES      := BindableProperty.new()  # 异常抗性

func init_by_db(actor_name: StringName) -> void:
	base_attr = ActorBaseAttr.new(actor_name)
	LV.set_maximum(Game.MAX_LEVEL)
	LV.set_value(1)
	my_exp.set_maximum(100) # todo 读经验表
	my_exp.set_value(0)
	update_all_by_base_attr()

# 根据基础属性，计算并赋值所有战斗属性
func update_all_by_base_attr() -> void:
	pass

func on_init() -> void:
	HP.register(on_HP_change)
	MP.register(on_MP_change)

func _init(a) -> void:
	_actor = a
	var has_save := false
	if has_save:
		return # todo 读档
	else: # 读数据表
		init_by_db(a.my_name)

func on_HP_change(new_HP) -> void:
	send_event("actor_hp_changed", [_actor, new_HP])

func on_MP_change(new_MP) -> void:
	send_event("actor_mp_changed", [_actor, new_MP])
