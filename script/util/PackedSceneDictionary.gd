class_name PackedSceneDictionary
extends Resource

@export var packed_scene: Dictionary = {}:
	set(value):
		# 类型验证
		var cleaned_dict = {}
		for key in value:
			if value[key] is PackedScene:
				cleaned_dict[key] = value[key]
			else:
				push_error("字典键 %s 的值类型错误: 期望 PackedScene，得到 %s" % [key, typeof(packed_scene[key])])
		packed_scene = cleaned_dict

func exists(key) -> bool:
	return packed_scene.has(key)

func get_scene(key) -> PackedScene:
	return packed_scene[key]
