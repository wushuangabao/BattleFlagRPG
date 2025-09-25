class_name FlagLayer
extends TileMapLayer

@export var unit_team_id : Dictionary[StringName, Game.TeamID]
@export var cell_team_id : Dictionary[Vector2i, Game.TeamID]
@export var player_team_id : Array[Game.TeamID] = []

func get_flag_units() -> Dictionary[StringName, Array]:
	var Dict : Dictionary[StringName, Array] = {}
	var cells := get_used_cells()
	for cell in cells:
		var data = get_cell_tile_data(cell)
		if data and data.has_custom_data("unit"):
			var u_name : StringName = data.get_custom_data("unit")
			if Dict.has(u_name):
				Dict[u_name].append(cell)
			else:
				Dict[u_name] = [cell]
	return Dict

func get_team_by_cell(c: Vector2i) -> Game.TeamID:
	# 1.通过单位名称获取队伍
	var data = get_cell_tile_data(c)
	if data and data.has_custom_data("unit"):
		var u_name : StringName = data.get_custom_data("unit")
		if unit_team_id.has(u_name):
			return unit_team_id[u_name]
	# 2.通过图块在图集中的坐标获取队伍
	var tmp := get_cell_atlas_coords(c)
	if cell_team_id.has(tmp):
		return cell_team_id[tmp]
	# 3.默认为红色队伍
	return Game.TeamID.Red

func is_player_team(t: Game.TeamID) -> bool:
	return player_team_id.has(t)

func get_player_team_id() -> Array[Game.TeamID]:
	return player_team_id
