class_name FlagLayer
extends TileMapLayer

@export var red_team : Array[Vector2i]
@export var green_team : Array[Vector2i]

var _red_team : HashSet
var _green_team : HashSet

func _ready() -> void:
	_red_team = HashSet.new(red_team)
	_green_team = HashSet.new(green_team)

func get_flag_units() -> Dictionary:
	var Dict := {}
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
	var tmp := get_cell_atlas_coords(c)
	if _green_team.has(tmp):
		return Game.TeamID.Green
	elif _red_team.has(tmp):
		return Game.TeamID.Red
	else:
		return Game.TeamID.Blue
