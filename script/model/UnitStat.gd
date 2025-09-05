# 管理单位的数据
class_name UnitStat extends AbstractModel

var HP       := AttributeBase.new()
var MP       := AttributeBase.new()

func on_init():
	HP.register_with_init_value_no_emit_first(0, on_HP_change)
	MP.register_with_init_value_no_emit_first(0, on_MP_change)
	## 记录存档的属性
	register_saveable_properties([
		"HP", "MP"
	])
	## 恢复存档
	super.on_init()
	
func on_HP_change(new_HP):
	save_model()
	send_event("event_count", new_HP)

func on_MP_change(new_MP):
	save_model()
	send_event("event_count", new_MP)	
