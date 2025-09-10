class_name CombatArchitecture extends Architecture

var actor_stat : Dictionary[ActorController, UnitStat] = {}

func _init() -> void:
	self.register_system(Game.g_combat)
	self.register_system(Game.g_actors)
	make_sure_architecture()

func register_actor(actor: ActorController) -> void:
	if not actor_stat.has(actor):
		actor_stat[actor] = actor.my_stat
		actor.set_architecture(self)
		actor.my_stat.on_init()

func unregister_actor(actor: ActorController) -> void:
	if actor_stat.has(actor):
		actor_stat.erase(actor)

func get_actor_stat(actor: ActorController):
	if actor_stat.has(actor):
		return actor_stat[actor]
	else:
		push_error("战斗框架中不存在角色：", actor.my_name)
