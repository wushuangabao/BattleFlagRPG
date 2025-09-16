class_name ActionRecover extends ActionBase

var recover_x = 0.1

func _init() -> void:
	target_type = TargetType.None
	cost = {
		&"AP" : 1
	}

func get_action_name() -> StringName:
	return &"recover"

func start(actor: ActorController) -> void:
	var recover_hp = actor.get_MaxHP() * recover_x
	var recover_mp = actor.get_MaxMP() * recover_x
	print(actor.my_name, " 恢复了 ", recover_hp, " HP、", recover_mp, " MP。消耗AP：", cost[&"AP"])
	actor.add_HP(recover_hp)
	actor.add_MP(recover_mp)
	_state = ActionState.Terminated