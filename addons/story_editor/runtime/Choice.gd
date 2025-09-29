class_name Choice extends Resource

@export var text: String
@export var text_disabled: String
@export var condition: Evaluator
@export var effects: Array[ChoiceEffect]

@export_storage var port: String # 对应 outputs 的出口名

func _init(p_text := ""):
	text = p_text
	text_disabled = "Locked Yet"
	port = ""
	condition = null
	effects = []
