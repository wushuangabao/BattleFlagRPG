class_name StoryGraph extends Resource

var id: String
@export var title: String = ""
@export var entry_node: String = ""
@export var nodes: Array[StoryNode] = []

func get_node_by_id(node_id: String) -> StoryNode:
	for n in nodes:
		if n.id == node_id:
			return n
	return null

func add_node(n: StoryNode) -> void:
	nodes.append(n)

func remove_node(node_id: String) -> void:
	for i in nodes.size():
		if nodes[i].id == node_id:
			nodes.remove_at(i)
			return

func ensure_entry() -> void:
	if (entry_node == null or entry_node.is_empty()) and nodes.size() > 0:
		entry_node = nodes[0].id
