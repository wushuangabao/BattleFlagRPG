class_name ActionBase

enum ActionState {
	Uninitialized, Running, Terminated
}
var _state : ActionState = ActionState.Uninitialized

enum TargetType {
	Unit,
	Cell,
	None
}
var target_type : TargetType
var target_highlight_type : UnitAnimatedSprite3D.HighLightType
var target
var cost   : Dictionary[StringName, int]

func get_action_name() -> StringName:
	return &"Base"

func get_state() -> ActionState:
	return _state

func validate(actor: ActorController) -> bool:
	if Game.g_combat.get_battle_state() != BattleSystem.BattleState.ActorIdle:
		print_debug("动作 %s 校验失败，当前战斗状态是 %d" % [get_action_name(), Game.g_combat.get_battle_state()])
		return false
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

func get_targets_on_cells(cells: Array[Vector2i], me: ActorController) -> Array[ActorController]:
	var targets_chose : Array[ActorController] = []
	for cell in cells:
		var a = Game.g_combat.get_actor_on_cell(cell)
		if a:
			targets_chose.append(a)
	if targets_chose.size() > 0:
		check_target_units(targets_chose, me) # 会过滤掉无效的目标
	return targets_chose

func chose_target(cells_chose: Array[Vector2i], me: ActorController) -> bool:
	match target_type:
		TargetType.Cell:
			if check_target_cells(cells_chose, me):
				target = cells_chose
				return true
		TargetType.Unit:
			var targets_chose := get_targets_on_cells(cells_chose, me)
			if targets_chose.size() > 0:
				target = targets_chose
				return true
	return false

func check_target_cells(_cells: Array[Vector2i], _a: ActorController) -> bool:
	return true

func check_target_units(_targets: Array[ActorController], _me: ActorController) -> bool:
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

func execute(a: ActorController) -> ActionState:
	_state = ActionState.Running
	start(a)
	return _state

# 立即执行一次
func start(_a: ActorController) -> void:
	_state = ActionState.Terminated

# 在角色_process中执行
func update(_a: ActorController, _delta: float) -> void:
	_state = ActionState.Terminated
