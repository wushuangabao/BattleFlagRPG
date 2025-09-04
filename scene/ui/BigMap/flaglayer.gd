class_name FlagLayer
extends TileMapLayer

func get_flag_units() -> Dictionary:
	var cells := get_used_cells()
	return {
		"test_actor" : Vector2i(2, 3)
	}
