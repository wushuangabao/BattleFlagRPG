class_name ActionBase

enum TargetType {
	Unit,
	Cell,
	None
}
var target : TargetType
var cost   : Dictionary[StringName, int]

func get_action_name() -> String:
	return "Base"

func validate(actor: ActorController) -> bool:
	for s in cost:
		match s:
			&"HP":
				if actor.get_HP() <= cost[s]:
					return false
			&"MP":
				if actor.get_MP() < cost[s]:
					return false
			&"AP":
				if actor.get_AP() < cost[s]:
					return false
	return true

func pay_costs(actor: ActorController) -> void:
	for s in cost:
		match s:
			&"HP":
				actor.add_HP(-cost[s])
			&"MP":
				actor.add_MP(-cost[s])
			&"AP":
				actor.pay_AP(cost[s])

func execute(_a: ActorController) -> void:
	pass
