class_name Choice extends Resource

var _text: String = ""
var _text_disabled: String = ""
var _condition: Evaluator = null
var _effects: Array[ChoiceEffect] = []
var _port: String = "" # 对应 outputs 的出口名

@export var text: String:
	get: return _text
	set(value):
		if _text == value:
			return
		_text = value
		emit_changed()

@export var text_disabled: String:
	get: return _text_disabled
	set(value):
		if _text_disabled == value:
			return
		_text_disabled = value
		emit_changed()

@export var condition: Evaluator:
	get: return _condition
	set(value):
		if _condition == value:
			return
		_condition = value
		emit_changed()

@export var effects: Array[ChoiceEffect]:
	get: return _effects
	set(value):
		if _effects == value:
			return
		_effects = value
		emit_changed()

@export var port: String:
	get: return _port
	set(value):
		if _port == value:
			return
		_port = value
		emit_changed()

func _init(p_text := "", p_port := "out"):
	_text = p_text
	_port = p_port
