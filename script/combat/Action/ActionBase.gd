class_name ActionBase

enum TargetType {
	Unit,
	Cell,
	None
}
var target : TargetType
var cost   : Dictionary[StringName, int]

func validate() -> bool:
	return true

func pay_costs(actor: ActorController) -> bool:
	var ok := true
	for s in cost:
		match s:
			&"HP":
				if actor.get_HP() <= cost[s]:
					ok = false
			&"MP":
				if actor.get_MP() < cost[s]:
					ok = false
			&"AP":
				if actor.get_AP() < cost[s]:
					ok = false
		if not ok:
			return false
	for s in cost:
		match s:
			&"HP":
				actor.add_HP(-cost[s])
			&"MP":
				actor.add_MP(-cost[s])
			&"AP":
				actor.pay_AP(cost[s])
	return true

func execute() -> void: # 可分帧播放
	pass

func prediction(context): # 供 UI 预览
	pass
