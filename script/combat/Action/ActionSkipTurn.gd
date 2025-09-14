class_name ActionSkipTurn extends ActionBase

func _init() -> void:
	target = TargetType.None
	cost = {}

func get_action_name() -> StringName:
	return &"skip_turn"
