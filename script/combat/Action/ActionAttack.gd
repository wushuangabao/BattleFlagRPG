class_name ActionAttack extends ActionBase

func _init() -> void:
	target_type = TargetType.Unit
	cost = {
		&"AP" : 2
	}

func get_action_name() -> StringName:
	return &"attack"

func check_target_unit(chosed_target: ActorController, me: ActorController) -> bool:
	var cell = me.base3d.get_cur_cell()
	var cells = GridHelper.neighbors4(cell)
	for c in cells:
		var a = Game.g_combat.get_actor_on_cell(c)
		if a and a.team_id != me.team_id and a == chosed_target:
			return true
	return false

func start(actor: ActorController) -> void:
	print(actor.my_name, " 对 ", target.my_name, " 发动了攻击！消耗AP：", cost[&"AP"])
	actor.anim_player.play(&"attack")
	target.animate_take_damage_after(0.75)
	_state = ActionState.Running

# 在角色_process中执行
func update(actor: ActorController, _delta: float) -> void:
	if not actor.anim_player.is_playing() and actor.anim_player.animation == &"attack":
		actor.anim_player.play(&"idle")
		target.anim_player.play(&"idle")
		_state = ActionState.Terminated
		var target_actor = target as ActorController
		target_actor.take_damage(80, actor)
