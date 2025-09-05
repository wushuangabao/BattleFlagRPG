class_name TurnController

signal turn_started
signal turn_ended

var timeline: TimelineController

func set_timeline(tl: TimelineController) -> void:
	timeline = tl

func do_turn(actor: ActorController) -> void:
	turn_started.emit(actor)
	var brain := actor.brain
	while actor.is_alive():
		var action: ActionBase = await brain.request_action(actor)
		if action == null:
			break
		if not action.validate():
			continue
		if not action.pay_costs(actor):
			break
		action.execute()  # 执行动画/效果
		if not brain.allow_more_actions(actor):
			break
		# 无可行动或玩家主动结束
		if not await brain.has_affordable_actions(actor):
			break
	turn_ended.emit(actor)
	timeline.resume()
