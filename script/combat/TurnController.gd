class_name TurnController extends AbstractController

signal turn_started
signal turn_ended

var timeline: TimelineController
var _brain  : BrainBase

func set_timeline(tl: TimelineController) -> void:
	timeline = tl

func _init() -> void:
	_brain = BrainBase.new()

func do_turn(actor: ActorController) -> void:
	print("现在是 ", actor.my_name, "的回合...")
	_brain.start_new_turn(actor, BrainBase.BrainType.Player)
	set_architecture(actor.m_architecture)
	actor.AP.register(func(_new_ap):
		timeline.set_actor_sprite_x(actor, true)
	)
	turn_started.emit(actor)
	while actor.is_alive():
		var action: ActionBase = await _brain.chose_an_action
		if action == null:
			print("动作无效 - ", actor.my_name)
			break
		if not action.validate(actor):
			print("动作未通过校验 - ", actor.my_name)
			continue
		action.pay_costs(actor)
		await action.execute(actor)  # 执行动画/效果
		if not _brain.allow_more_actions(actor):
			break
		# 无可行动或玩家主动结束
		# if not await _brain.has_affordable_actions(actor):
		# 	break
	_brain.set_type(BrainBase.BrainType.Invalid)
	turn_ended.emit(actor)
	timeline.resume()

func _on_attack_button_pressed() -> void:
	if _brain and _brain.is_valid():
		print("角色选择攻击动作")
		_brain.set_attack_action()

func on_map_cell_clicked_twice(path: Array[Vector2i]) -> void:
	if _brain and _brain.is_valid():
		print("角色选择移动")
		_brain.set_move_action(path)
