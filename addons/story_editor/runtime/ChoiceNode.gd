class_name ChoiceNode extends StoryNode

class Choice:
	var text: String
	var condition: Resource = null # Condition
	var effects: Array[Resource] = [] # Array[Effect]
	var port: String = "" # 对应 outputs 的出口名
	func _init(p_text := "", p_port := "out"):
		text = p_text
		port = p_port

@export var choices: Array[Dictionary] = [] 
# 每项结构：
# { "text": "选项一", "port": "A", "condition": Resource, "effects": Array[Resource] }
