class_name StoryNode extends Resource

@export_storage var id: String
@export_storage var position: Vector2
@export_storage var outputs: Dictionary[String, String]

@export var name: String

# 进入节点时执行的效果
@export var effects: Array[ChoiceEffect]

# 确保每个实例拥有独立的容器，避免共享引用
func _init() -> void:
	outputs = {}
	effects = []

func get_output_port_names() -> Array:
	return outputs.keys() if outputs != null else []

func get_next_for(port_name: String) -> String:
	if outputs == null:
		return ""
	return outputs.get(port_name, "")
