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

func end_this_turn() -> void:
	_actor = null
	_type = BrainBase.BrainType.Invalid

func get_type() -> BrainType:
	return _type

func is_valid() -> bool:
	return not _type == BrainType.Invalid
