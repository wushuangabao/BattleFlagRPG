class_name Choice extends Resource

@export var text: String
@export var text_disabled : String
@export var condition: Evaluator = null
@export var effects: Array[ChoiceEffect] = []
@export var port: String = "" # 对应 outputs 的出口名

func _init(p_text := "", p_port := "out"):
	text = p_text
	port = p_port
