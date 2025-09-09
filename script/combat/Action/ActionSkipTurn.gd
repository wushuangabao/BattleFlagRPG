class_name ActionSkipTurn extends ActionBase

func _init() -> void:
	target = TargetType.None
	cost = {}

func get_action_name() -> StringName:
	return &"skip_turn"

# 立即执行一次
func start(_actor: ActorController) -> void:
	print("执行动作 - 跳过回合")
	_state = ActionState.Terminated