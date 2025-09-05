class_name FlagLayer
extends TileMapLayer

func get_flag_units() -> Dictionary:
	var Dict := {}
	var cells := get_used_cells()
	for cell in cells:
		var data = get_cell_tile_data(cell)
		if data and data.has_custom_data("unit"):
			var u_name : StringName = data.get_custom_data("unit")
			var pos : Vector2i = Vector2i(cell.x, cell.y)
			if Dict.has(u_name):
				Dict[u_name].append(pos)
			else:
				Dict[u_name] = [pos]
	return Dict
