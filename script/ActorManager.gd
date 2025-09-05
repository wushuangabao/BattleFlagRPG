# 角色管理器
class_name ActorManager extends Node

@export var actors : PackedSceneDictionary # 存储角色对应的 UnitBase3D 节点
var _actors_nameList : Array[StringName]   # 所有角色的角色名
var _actors_nameMap  : Dictionary = {}:    # 所有角色的控制器
	set(value):
		var cleaned_dict = {}
		for key in value:
			if value[key] is ActorController:
				cleaned_dict[key] = value[key]
			else:
				push_error("字典键 %s 的值类型错误: 期望 ActorController，得到 %s" % [key, typeof(_actors_nameMap[key])])
		_actors_nameMap = cleaned_dict

func _ready() -> void:
	for actor in actors.keys():
		_actors_nameList.append(actor)
	Game.g_actors = self

func get_actor_by_name(actor_name: StringName) -> ActorController:
	if _actors_nameMap.has(actor_name):
		return _actors_nameMap[actor_name]
	else:
		if Game.Debug == 1:
			print("create new actor: ", actor_name)
		if actors.exists(actor_name) == false:
			push_error("get_actor_by_name: ", actor_name, " is invalid")
			return null
		var new_actor = ActorController.new(actor_name)
		if _is_character(actor_name):
			_actors_nameMap[actor_name] = new_actor
		return new_actor

# 是否为全局唯一的角色（属性是随着游戏进程而变化的）
func _is_character(actor_name: StringName) -> bool:
	return is_character(actors.get_scene(actor_name))
# 这种角色需要特殊命名节点
func is_character(actor_template: PackedScene) -> bool:
	var actor_state := actor_template.get_state()
	var node_cnt := actor_state.get_node_count()
	if node_cnt >= 3:
		for i in range(node_cnt):
			if actor_state.get_node_name(i) == &"ActorDefault":
				return true
	return false
