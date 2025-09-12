class_name ActionAttack extends ActionBase

var targets : Array[Vector2i]
var _target_unit_type : ActionBase.TargetUnitType

func _init() -> void:
	target_type = TargetType.Unit
	_target_unit_type = ActionBase.TargetUnitType.OtherTeam
	cost = {
		&"AP" : 2
	}

func get_action_name() -> StringName:
	return &"attack"

func check_target_unit(chosed_target: ActorController, me: ActorController) -> bool:
	var cell = me.base3d.get_cur_cell()
	var cells = GridHelper.neighbors4(cell)
	targets = []
	for c in cells:
		var a = Game.g_combat.get_actor_on_cell(c)
		if a and a.team_id != me.team_id:
			targets.append(c)
	if targets.size() > 0 and targets.has(chosed_target):
		return true
	return false

func start(actor: ActorController) -> void:
	print(actor.my_name, " 对 ", target.my_name, " 发动了攻击！，消耗AP：", cost[&"AP"])
	_state = ActionState.Terminated

# 在角色_process中执行
func update(_actor: ActorController, _delta: float) -> void:
	_state = ActionState.Terminated