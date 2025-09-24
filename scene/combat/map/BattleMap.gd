class_name BattleMap
extends CanvasLayer

signal battle_map_ready

@onready var ground : GroundLayer = $TilemapRoot2D/Ground
@onready var flag   : FlagLayer   = $TilemapRoot2D/Flag

func _ready() -> void:
	call_deferred(&"_emit_signal_ready") # 若直接在这里发送信号，BattleMapContainer 里的 await 会错过

func _emit_signal_ready():
	battle_map_ready.emit()
