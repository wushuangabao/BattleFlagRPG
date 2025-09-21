class_name ActorBaseAttr

const MAX_VALUE := 100

enum BaseAttrName {
	STR, # 力量
	CON, # 根骨
	AGI, # 身法
	WIL, # 定力
	INT  # 悟性
}

var _actor : ActorController
var attrs  : Array[AttributeBase]

func _init(actor, name) -> void:
	_actor = actor
	for i in range(5):
		var a = Game.g_luban.get_actor_attr(name, i)
		var attr = AttributeBase.new(actor, a, MAX_VALUE)
		attrs.push_back(attr)

func register(on_base_attr_change: Callable) -> void:
	for i in attrs.size():
		attrs[i].register(on_base_attr_change.bind(i))

func at(attr_idx: int) -> int:
	return attrs[attr_idx].value

static func get_base_attr_name(attr_type: BaseAttrName) -> String:
	var attr_dic = Game.get_base_attrs().get(attr_type)
	return attr_dic["name"]
