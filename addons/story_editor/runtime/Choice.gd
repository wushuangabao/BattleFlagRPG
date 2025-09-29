@tool
class_name Choice extends Resource

var _text: String = ""

@export var text: String: set = set_text, get = get_text
@export var text_disabled: String
@export var condition: Evaluator
@export var effects: Array[ChoiceEffect]

@export_storage var port: String # 对应 outputs 的出口名

func set_text(value: String) -> void:
	if _text == value:
		return
	_text = value
	emit_changed()

func get_text() -> String:
	return _text

func _init(p_text := ""):
	_text = p_text
	text_disabled = "Locked Yet"
	port = ""
	condition = null
	effects = []
