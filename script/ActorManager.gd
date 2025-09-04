# 角色管理器
class_name ActorManager

# 所有角色的角色名
var _actors_nameList : Array[StringName] = [
	&"test_actor"
]
# 所有角色的控制器
var _actors_nameMap  : Dictionary = {}:
	set(value):
		var cleaned_dict = {}
		for key in value:
			if value[key] is ActorController:
				cleaned_dict[key] = value[key]
			else:
				push_error("字典键 %s 的值类型错误: 期望 ActorController，得到 %s" % [key, typeof(_actors_nameMap[key])])
		_actors_nameMap = cleaned_dict

func get_actor_by_name(actor_name: StringName) -> ActorController:
	if _actors_nameMap.has(actor_name):
		return _actors_nameMap[actor_name]
	else:
		push_error("get actor by name ", actor_name, "不存在")
		return null

func _init() -> void:
	for actor_name in _actors_nameList:
		_actors_nameMap[actor_name] = ActorController.new(actor_name)
