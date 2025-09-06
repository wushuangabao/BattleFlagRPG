class_name BrainBase

enum BrainType {
	Invalid,
	AI,
	Player
}

signal chose_an_action

var _type := BrainType.Invalid
var _actor : ActorController

func start_new_turn(a: ActorController, t:BrainType) -> void:
	_actor = a
	_type = t

func get_type() -> BrainType:
	return _type

func is_valid() -> bool:
	return not _type == BrainType.Invalid

func set_attack_action() -> void:
	var action = ActionAttack.new()
	chose_an_action.emit(action)

func set_move_action(path: Array[Vector2i]) -> void:
	var action = ActionMove.new(path)
	chose_an_action.emit(action)

func allow_more_actions(actor: ActorController) -> bool:
	return false

func has_affordable_actions(actor: ActorController) -> bool:
	return false
