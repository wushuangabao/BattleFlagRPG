class_name BrainBase extends Node

enum BrainType {
	AI,
	Player
}

var _actor : ActorController

func _init(a: ActorController) -> void:
	_actor = a

func request_action(actor: ActorController) -> ActionBase:
	await get_tree().create_timer(2.0).timeout
	return ActionBase.new()

func allow_more_actions(actor: ActorController) -> bool:
	return false

func has_affordable_actions(actor: ActorController) -> bool:
	return false
