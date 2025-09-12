class_name TurnController extends AbstractController

var timeline : TimelineController

var _actor

func set_timeline(tl: TimelineController) -> void:
	timeline = tl

func do_turn(actor: ActorController) -> void:
	print("现在是 ", actor.my_name, "的回合...（AP=", actor.get_AP(), "）")
	_actor = actor
	var battle = Game.g_combat
	while _actor.is_alive():
		# 无可用的行动
		if not has_affordable_actions(_actor):
			break
		# 选择动作
		battle.begin_to_chose_action_for(_actor)
		var action: ActionBase = await Game.g_combat.action_chosed
		if action == null:
			print("动作无效 - ", _actor.my_name)
			continue
		if action.get_action_name() == &"skip_turn":
			break
		if not action.validate(_actor):
			print("动作未通过校验 - ", _actor.my_name)
			continue
		# 选择目标
		if action.target_type != ActionBase.TargetType.None:
			var ok = await battle.chose_action_target(_actor, action)
			if not ok:
				continue
		# 动作消耗
		action.pay_costs(_actor)
		timeline.update_actor_btn_pos(_actor, true)
		# 执行动作
		await battle.let_actor_do_action(_actor, action)
	battle.turn_ended(_actor)
	timeline.resume_timeline()
	_actor = null

func change_cur_actor_to(actor: ActorController) -> bool:
	if actor.get_AP() < TimelineController.AP_THRESHOLD:
		return false
	if actor.get_state() == ActorController.ActorState.DoAction:
		return false
	timeline.set_actor_actived_on_timeline(actor)
	if _actor == null:
		do_turn(actor)
	else:
		print("已经切换到 ", actor.my_name, "的回合...（AP=", actor.get_AP(), "）")
		_actor = actor
	return true

func has_affordable_actions(actor: ActorController) -> bool:
	if actor.get_AP() > 0:
		return true
	else:
		return false
