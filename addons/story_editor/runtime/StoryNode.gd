class_name StoryNode extends Resource

@export var id: String = ""
@export var name: String = ""
@export var position: Vector2 = Vector2.ZERO # 编辑器中的位置

# 出口连线：出口名 -> 目标节点 id（最小实现）
@export var outputs: Dictionary[String, String] = {} # { "out": "node_id", "A": "n2" }

# 进入节点时执行的效果
@export var effects: Array[ChoiceEffect] = [] # Array[Effect]

func get_output_port_names() -> Array:
	return outputs.keys()

func get_next_for(port_name: String) -> String:
	return outputs.get(port_name, "")
