class_name ActionChangeFacingDir extends ActionBase

var _dir: ActorController.FacingDirection

func _init(dir: ActorController.FacingDirection) -> void:
	_dir = dir
	target_type = TargetType.None
	cost = {
		&"AP": 0
	}

func get_action_name() -> StringName:
	return &"change_facing"

func validate(actor: ActorController) -> bool:
	return super.validate(actor)

# 立即执行：改变角色朝向
func start(actor: ActorController) -> void:
	actor.facing_direction = _dir
	if actor.base3d:
		actor.base3d._dir = actor.get_facing_vector()
		actor.base3d.facing_dirty = true
	_state = ActionState.Terminated
