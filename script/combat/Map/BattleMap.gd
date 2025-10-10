class_name BattleMap
extends CanvasLayer

signal battle_map_ready

@export var win_checker  : Evaluator = null
@export var lose_checker : Evaluator = null

@export var ground : GroundLayer
@export var flag   : FlagLayer

func _ready() -> void:
	call_deferred(&"_emit_signal_ready") # 若直接在这里发送信号，BattleMapContainer 里的 await 会错过

func _emit_signal_ready():
	battle_map_ready.emit()
