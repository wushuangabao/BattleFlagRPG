extends Node2D
class_name OverLay

var grid: Ground # 指向 Ground 类型的父节点

func _draw():
	# 可达范围
	for cell in grid.reachable.keys():
		var center: Vector2 = grid.map_to_local(cell)
		var top_left: Vector2 = center - Vector2(GridHelper.cell_size) * 0.5
		draw_rect(Rect2(top_left, Vector2(GridHelper.cell_size)), grid.color_range, true)
	# 路径
	if grid.path_cells.size() > 1:
		var points: PackedVector2Array = []
		for c in grid.path_cells:
			points.append(grid.map_to_local(c))
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], grid.color_path_line, grid.path_line_width)
		for p in points:
			draw_circle(p, min(GridHelper.cell_size.x, GridHelper.cell_size.y) * 0.12, grid.color_path_node)
