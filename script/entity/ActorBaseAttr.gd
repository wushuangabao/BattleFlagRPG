class_name ActorBaseAttr

enum BaseAttrName {
	STR, # 力量
	CON, # 根骨
	AGI, # 身法
	WIL, # 定力
	INT  # 悟性
}

var attrs : Array[AttributeBase]

func _init(name) -> void:
	var a = LubanDB.GetActorBaseAttr(name)
	attrs = a.duplicate()
