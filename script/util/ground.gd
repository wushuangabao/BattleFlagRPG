extends TileMapLayer
class_name Ground

@export_group("highlight_area")
# 移动边界线
@export var color_range_border: Color = Color(0.1, 0.9, 0.1, 0.95)
# 目标选择范围
@export var color_range_chose: Color = Color(0.2, 0.6, 1.0, 0.4)
# 技能作用范围
@export var color_range_skill: Color = Color(0.0, 0.86, 0.74, 0.8)

@export_group("highlight_cell")
@export var color_hgihtlight_rect: Dictionary[StringName, Color] = {
	&"reachable" : Color(0.1, 0.9, 0.1, 0.9),
	&"unreachable" : Color(0.9, 0.1, 0.1, 0.9)
}
@export var color_hgihtlight_circle: Dictionary[StringName, Color] = {
	&"current_actor" : Color(0.1, 0.9, 0.1, 0.98)
}
@export var color_hgihtlight_circle_border: Dictionary[StringName, Color] = {
	&"select_teammember" : Color(0.1, 0.9, 0.1, 0.98),
	&"select_other_team_actor" : Color(0.9, 0.1, 0.1, 0.98)
}

var hightlight_cell_map: Dictionary[StringName, Vector2i] = {
	&"reachable" : Vector2i(-1, -1),
	&"unreachable" : Vector2i(-1, -1),
	&"current_actor" : Vector2i(-1, -1),
	&"select_teammember" : Vector2i(-1, -1),
	&"select_other_team_actor" : Vector2i(-1, -1)
}
# 互斥的高亮格子（一个高亮之后，其他的就不能高亮）
var exclusive_hightlight_cell_set: HashSet = HashSet.new([
	&"reachable", &"unreachable", &"select_teammember", &"select_other_team_actor"
])

@export_group("move_path")
@export var color_path_line: Color = Color(0.9, 0.95, 1.0, 0.95)
@export var color_path_node: Color = Color(0.2, 0.6, 1.0, 0.95)
@export var path_line_width: float = 3.0

var overlay: OverLay = null
var reachable_map: Dictionary = {} # cell->steps
var path_cells: Array[Vector2i] = []

var chose_area_cells: Array[Vector2i] = []
var skill_area_cells: Array[Vector2i] = []

func _ready():
	# 创建overlay节点用于绘制移动范围和路径
	if overlay == null:
		overlay = OverLay.new()
		overlay.grid = self
		add_child(overlay)
	# 让整个 TileMapLayer 半透明
	modulate.a = 0.5

func set_reachable(cells: Dictionary):
	reachable_map = cells
	overlay.queue_redraw()

func set_chose_area(area: Array[Vector2i]):
	chose_area_cells = area
	overlay.queue_redraw()

func set_skill_area(area: Array[Vector2i]):
	skill_area_cells = area
	overlay.queue_redraw()

func set_path(path: Array[Vector2i]):
	path_cells = path
	overlay.queue_redraw()

func clear_path():
	path_cells.clear()
	overlay.queue_redraw()

func clear_on_cur_actor_move() -> void:
	set_reachable({})
	highlight_cell(Vector2i(-1, -1), &"current_actor")

func highlight_cell(cell: Vector2i, witch: StringName) -> void:
	if not hightlight_cell_map.has(witch):
		return
	if hightlight_cell_map[witch] == cell:
		return
	hightlight_cell_map[witch] = cell
	if exclusive_hightlight_cell_set.has(witch):
		for k in exclusive_hightlight_cell_set.to_array():
			if k != witch:
				hightlight_cell_map[k] = Vector2i(-1, -1)
	overlay.queue_redraw()

func clear_on_change_cur_actor_to(a: ActorController) -> void:
	highlight_cell(a.base3d.get_cur_cell(), &"current_actor")
	for k in exclusive_hightlight_cell_set.to_array():
		hightlight_cell_map[k] = Vector2i(-1, -1)
	clear_path()
	set_reachable({})
	overlay.queue_redraw()

# 可扩展点
# 地形移动成本：把 movement_range 的步长1改为 terrain_cost[n]；路径预览仍用 A* 的 g 值+cost。
# 视觉增强：使用 NinePatchRect 或 MultiMeshInstance2D 批量绘制，或者在 Overlay 中缓存 Mesh，减少 draw 调用。

func get_tilemap_dimensions() -> Vector2i:
	var used_rect := get_used_rect()
	var columns: int = used_rect.size.x #- used_rect.position.x
	var rows: int = used_rect.size.y #- used_rect.position.y
	return Vector2i(columns, rows)
