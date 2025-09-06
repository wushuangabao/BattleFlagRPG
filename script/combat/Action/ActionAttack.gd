class_name ActionAttack extends ActionBase

func _init() -> void:
	target = TargetType.Unit
	cost = {
		&"AP" : 5
	}

func get_action_name() -> String:
	return "attack"

func execute(actor: ActorController) -> void:
	print("攻击！")
