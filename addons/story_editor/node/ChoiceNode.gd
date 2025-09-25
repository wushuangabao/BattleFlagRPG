class_name ChoiceNode extends StoryNode

@export var choices: Array[Choice] = [] 
# 每项结构：
# { "text": "选项一", "port": "A", "condition": Evaluator, "effects": Array[ChoiceEffect] }
