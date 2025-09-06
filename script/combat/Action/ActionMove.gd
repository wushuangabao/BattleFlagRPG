class_name ActionMove extends ActionBase

func _init(path: Array[Vector2i]) -> void:
	cost = {
		&"AP" : path.size() - 1
	}

func get_action_name() -> String:
	return "移动"

func execute(actor: ActorController) -> void:
	print("执行动作 - 行走，消耗AP：", cost[&"AP"])
	Game.g_combat.let_actor_move(actor)
	await actor.base3d.reached_target_cell
