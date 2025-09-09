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
var target
var cost   : Dictionary[StringName, int]

func get_action_name() -> StringName:
	return &"Base"

func get_state() -> ActionState:
	return _state

func validate(actor: ActorController) -> bool:
	if Game.g_combat.get_battle_state() != BattleSystem.BattleState.ActorIdle:
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

func check_target_cell(_cell: Vector2i, _a: ActorController) -> bool:
	return true

func check_target_unit(_target: ActorController, _me: ActorController) -> bool:
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