# 角色管理器
class_name ActorManager extends AbstractSystem

@export var actors : PackedSceneDictionary # 存储角色对应的 UnitBase3D 节点
@export var timeline_icons : Dictionary[StringName, Texture2D]

static var _actors_nameMap  : Dictionary = {}:    # 所有角色的控制器
	set(value):
		var cleaned_dict = {}
		for key in value:
			if value[key] is ActorController:
				cleaned_dict[key] = value[key]
			else:
				push_error("字典键 %s 的值类型错误: 期望 ActorController，得到 %s" % [key, typeof(_actors_nameMap[key])])
		_actors_nameMap = cleaned_dict

# 初始化：创建具名角色的实例，建立全局引用
func _ready() -> void:
	for actor_name in actors.keys():
		if is_character(actor_name):
			var new_actor = ActorController.new()
			new_actor.set_actor_data(actor_name)
			_actors_nameMap[actor_name] = new_actor
	Game.g_actors = self
	print("角色管理器初始化完毕")

# 注册到架构时调用
func on_init():
	pass

func on_actor_hp_changed(actor, new_hp, _old_hp):
	print("ActorManager 收到信号：", actor.my_name, " hp=", new_hp)
func on_actor_mp_changed(actor, new_mp, _old_mp):
	print("ActorManager 收到信号：mp=", actor.my_name, " mp=", new_mp)

# 获取一个角色的 ActorController 实例
func get_actor_by_name(actor_name: StringName) -> ActorController:
	if _actors_nameMap.has(actor_name):
		return _actors_nameMap[actor_name]
	else:
		return null

# 是否为全局唯一的角色（属性是随着游戏进程而变化的）
# 这种角色称为具名角色，不存在名为 ActorDefault 的子节点
func is_character(actor) -> bool:
	if actor is StringName or actor is String:
		actor = actors.get_scene(actor)
	elif actor is UnitBase3D or actor is ActorController:
		if actor is ActorController:
			actor = actor.base3d
		if actor.get_child_count() > 1:
			for child in actor.get_children():
				if child.name == &"ActorDefault":
					return false
		return true
	elif not actor is PackedScene:
		push_error("错误的参数类型 for ActorManager::is_charactor")
		return false
	var actor_template = actor as PackedScene
	var actor_state := actor_template.get_state()
	var node_cnt := actor_state.get_node_count()
	if node_cnt >= 3:
		for i in range(node_cnt):
			if actor_state.get_node_name(i) == &"ActorDefault":
				return false
	return true

func get_timeline_icon_by_actor_name(n: StringName) -> Texture2D:
	if timeline_icons.has(n):
		var texture: Texture2D = timeline_icons[n]
		if texture:
			return texture
	push_warning("加载 timeline 图标失败，角色名：", n)
	return timeline_icons[&"default"]
