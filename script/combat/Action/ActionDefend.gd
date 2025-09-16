class_name ActionDefend extends ActionBase

var _actor : ActorController

func _init() -> void:
	target_type = TargetType.None
	cost = {
		&"AP" : 1
	}

func get_action_name() -> StringName:
	return &"defend"

func validate(actor: ActorController) -> bool:
	if not super.validate(actor):
		return false
	return true

# 立即执行一次
func start(actor: ActorController) -> void:
	print("执行动作 - 防御，消耗AP：", cost[&"AP"])
	actor.anim_player.play(&"defend")
	_actor = actor
	_state = ActionState.Running

# 在角色_process中执行
func update(_a: ActorController, _delta: float) -> void:
	pass

func cancel() -> void:
	_actor.anim_player.play(&"idle")
	_actor._state = ActorController.ActorState.Idle