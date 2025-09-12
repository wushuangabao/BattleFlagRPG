class_name TurnController extends AbstractController

var timeline: TimelineController
var _brain  : BrainBase

func set_timeline(tl: TimelineController) -> void:
	timeline = tl

func _init() -> void:
	_brain = BrainBase.new()

func do_turn(actor: ActorController) -> void:
	print("现在是 ", actor.my_name, "的回合...（AP=", actor.get_AP(), "）")
	_brain.start_new_turn(actor, BrainBase.BrainType.Player)
	var battle = Game.g_combat
	
	while actor.is_alive():
		# 无可用的行动
		if not _brain.has_affordable_actions(actor):
			break
	
		battle.begin_to_chose_action_for(actor)
		var action: ActionBase = await Game.g_combat.action_chosed
		if action == null:
			print("动作无效 - ", actor.my_name)
			continue
		if action.get_action_name() == &"skip_turn":
			break
		if not action.validate(actor):
			print("动作未通过校验 - ", actor.my_name)
			continue
		
		match action.target_type:
			ActionBase.TargetType.Cell:
				await battle.chose_action_target_cell(actor, action)
			ActionBase.TargetType.Unit:
				await battle.chose_action_target_unit(actor, action)
		
		action.pay_costs(actor)
		timeline.update_actor_btn_pos(actor, true)
		await battle.let_actor_do_action(actor, action)

	_brain.end_this_turn()
	battle.turn_ended(actor)

	timeline.resume_timeline()

func _on_attack_button_pressed() -> void:
	if _brain and _brain.is_valid():
		print("角色选择攻击动作")
		_brain.set_attack_action()
