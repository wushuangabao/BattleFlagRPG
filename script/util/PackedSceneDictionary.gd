class_name PackedSceneDictionary
extends Resource

@export var packed_scene: Dictionary[StringName, PackedScene]

func exists(key) -> bool:
	return packed_scene.has(key)

func get_scene(key) -> PackedScene:
	return packed_scene[key]

func keys() -> Array[StringName]:
	return packed_scene.keys()
