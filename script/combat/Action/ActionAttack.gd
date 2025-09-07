class_name ActionAttack extends ActionBase

var targets : Array[Vector2i]

func _init() -> void:
	target = TargetType.Unit
	cost = {
		&"AP" : 2
	}

func get_action_name() -> String:
	return "attack"

func validate(actor: ActorController) -> bool:
	if not super.validate(actor):
		return false
	var cell = actor.base3d.get_cur_cell()
	var cells = GridHelper.neighbors4(cell)
	targets = []
	for c in cells:
		var a = Game.g_combat.get_actor_on_cell(c)
		if a and a.team_id != actor.team_id:
			targets.append(c)
	if targets.size() > 0:
		return true
	return false

func execute(actor: ActorController) -> void:
	var a_target : ActorController = await Game.g_combat.scene.on_click_actor_other_team
	print(actor.my_name, " 对 ", a_target.my_name, " 发动了攻击！")
