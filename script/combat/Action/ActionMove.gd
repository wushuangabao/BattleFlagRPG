class_name ActionMove extends ActionBase

func _init(path: Array[Vector2i]) -> void:
	cost = {
		&"AP" : path.size() - 1
	}

func get_action_name() -> String:
	return "移动"

func validate(actor: ActorController) -> bool:
	if not super.validate(actor):
		return false
	if cost[&"AP"] < 0:
		push_error("创建移动动作时，传入的 path 为空！")
		return false
	return true

func execute(actor: ActorController) -> void:
	print("执行动作 - 行走，消耗AP：", cost[&"AP"])
	Game.g_combat.let_actor_move(actor)
	await actor.base3d.reached_target_cell
