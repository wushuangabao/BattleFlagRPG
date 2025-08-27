extends Node

func goto_scene(scene_name):
	if get_child_count() > 0:
		get_child(0).queue_free()
	var packed = Game.scene.get(scene_name)
	add_child(packed.instantiate())
