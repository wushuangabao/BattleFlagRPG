# 管理单位的数据
class_name UnitStat extends AbstractModel

var _actor   :  ActorController
var HP       := AttributeBase.new()
var MP       := AttributeBase.new()

func on_init() -> void:
	HP.register_with_init_value_no_emit_first(0, on_HP_change)
	MP.register_with_init_value_no_emit_first(0, on_MP_change)

func _init(a) -> void:
	_actor = a

func on_HP_change(new_HP) -> void:
	send_event("actor_hp_changed", [_actor, new_HP])

func on_MP_change(new_MP) -> void:
	send_event("actor_mp_changed", [_actor, new_MP])
