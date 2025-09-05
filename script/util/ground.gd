extends TileMapLayer
class_name Ground

@export var color_range: Color = Color(0.2, 0.6, 1.0, 0.28)
@export var color_range_border: Color = Color(0.1, 0.9, 0.1, 0.95)
@export var color_hgihtlight_reachable: Color = Color(0.1, 0.9, 0.1, 0.95)
@export var color_hgihtlight_unreachable: Color = Color(0.9, 0.1, 0.1, 0.95)
@export var color_path_line: Color = Color(0.9, 0.95, 1.0, 0.95)
@export var color_path_node: Color = Color(0.2, 0.6, 1.0, 0.95)
@export var path_line_width: float = 3.0

var overlay: OverLay = null
var reachable: Dictionary = {} # cell->steps
var path_cells: Array[Vector2i] = []
var hightlight_cell_reachable := Vector2i(-1, -1)
var hightlight_cell_unreachable := Vector2i(-1, -1)

func _ready():
	# 创建overlay节点用于绘制移动范围和路径
	if overlay == null:
		overlay = OverLay.new()
		overlay.grid = self
		add_child(overlay)
	# 让整个 TileMapLayer 半透明
	modulate.a = 0.5

func set_reachable(cells: Dictionary):
	reachable = cells
	overlay.queue_redraw()

func set_path(path: Array[Vector2i]):
	path_cells = path
	overlay.queue_redraw()

func clear_path():
	path_cells.clear()
	overlay.queue_redraw()

func highlight_cell(cell: Vector2i, is_reachable: bool):
	if is_reachable and hightlight_cell_reachable != cell:
		hightlight_cell_reachable = cell
		hightlight_cell_unreachable = Vector2i(-1, -1)
	elif not is_reachable and hightlight_cell_unreachable != cell:
		hightlight_cell_unreachable = cell
		hightlight_cell_reachable = Vector2i(-1, -1)
	overlay.queue_redraw()

# 可扩展点
# 地形移动成本：把 movement_range 的步长1改为 terrain_cost[n]；路径预览仍用 A* 的 g 值+cost。
# 单位阻挡：在 is_blocked 中并入“占用格”字典，避免穿人；若允许穿队友可按 team 区分。
# 视觉增强：使用 NinePatchRect 或 MultiMeshInstance2D 批量绘制，或者在 Overlay 中缓存 Mesh，减少 draw 调用。
# 补间中断：移动中忽略输入；或提供“排队”系统，将后续路径入队。

func get_tilemap_dimensions() -> Vector2i:
	var used_rect := get_used_rect()
	var columns: int = used_rect.size.x #- used_rect.position.x
	var rows: int = used_rect.size.y #- used_rect.position.y
	return Vector2i(columns, rows)
