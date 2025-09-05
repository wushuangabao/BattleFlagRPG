class_name BattleMap
extends CanvasLayer

signal battle_map_ready

func _ready() -> void:
	battle_map_ready.emit()
