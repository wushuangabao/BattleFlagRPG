class_name ActionMove extends ActionBase

func _init(path: Array[Vector2i]) -> void:
	target_type = TargetType.None
	cost = {
		&"AP" : path.size() - 1
	}
	target = path.back()

func get_action_name() -> StringName:
	return &"move"

func validate(actor: ActorController) -> bool:
	if not super.validate(actor):
		return false
	if cost[&"AP"] < 0:
		push_error("创建移动动作时，传入的 path 为空！")
		return false
	return true

# 立即执行一次
func start(actor: ActorController) -> void:
	print("执行动作 - 行走，消耗AP：", cost[&"AP"])
	Game.g_combat.let_actor_move(actor)
	_state = ActionState.Running

# 在角色_process中执行
func update(actor: ActorController, _delta: float) -> void:
	if actor.base3d.is_arrived_target_cell():
		_state = ActionState.Terminated
