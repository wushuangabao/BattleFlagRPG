extends Node2D
class_name OverLay

var grid: Ground # 指向 Ground 类型的父节点

func _draw():
	# 可达范围
	var cells: Array[Vector2i] = []
	for cell in grid.reachable.keys():
		# var center: Vector2 = grid.map_to_local(cell)
		# var top_left: Vector2 = center - Vector2(GridHelper.cell_size) * 0.5
		# draw_rect(Rect2(top_left, Vector2(GridHelper.cell_size)), grid.color_range, false, 2.0)
		cells.push_back(cell)
	_draw_boundary(cells, grid.color_range, 2.0)
	# 路径
	if grid.path_cells.size() > 1:
		var points: PackedVector2Array = []
		for c in grid.path_cells:
			points.append(grid.map_to_local(c))
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], grid.color_path_line, grid.path_line_width)
		for p in points:
			draw_circle(p, min(GridHelper.cell_size.x, GridHelper.cell_size.y) * 0.12, grid.color_path_node)
	# 高亮可到达格子
	if grid.hightlight_cell_reachable.x >= 0 and grid.hightlight_cell_reachable.y >= 0:
		var center: Vector2 = grid.map_to_local(grid.hightlight_cell_reachable)
		var top_left: Vector2 = center - Vector2(GridHelper.cell_size) * 0.5
		draw_rect(Rect2(top_left, Vector2(GridHelper.cell_size)), grid.color_hgihtlight_reachable, true)
	# 高亮不可到达格子
	elif grid.hightlight_cell_unreachable.x >= 0 and grid.hightlight_cell_unreachable.y >= 0:
		var center: Vector2 = grid.map_to_local(grid.hightlight_cell_unreachable)
		var top_left: Vector2 = center - Vector2(GridHelper.cell_size) * 0.5
		draw_rect(Rect2(top_left, Vector2(GridHelper.cell_size)), grid.color_hgihtlight_unreachable, true)

# 绘制闭合的多边形轮廓
func _draw_boundary(cells: Array[Vector2i], color: Color, width: float) -> void:
	if cells.size() > 1:
		var cell_set = {}
		for cell in cells:
			cell_set[cell] = true
		# 按顺序收集多边形的顶点
		var edges = []
		for cell in cells:
			for i in range(4):
				var dir = GridHelper.DIRECTIONS[i]
				var neighbor = cell + dir
				# 如果邻居不在集合中，则这条边是边界
				if not cell_set.has(neighbor):
					var vertices = GridHelper.get_edge_vertices(grid, cell, i)
					edges.append(vertices)
		if edges.size() == 0:
			return
		var boundary = connect_edges(edges)
		if boundary.size() >= 4:
			draw_polyline(PackedVector2Array(boundary), color, width)
	
# 连接边界边形成连续的多边形
func connect_edges(edges: Array) -> Array:
	var boundary = []
	var vertex_to_edges = {} # 键为顶点，值为连接到该顶点的边
	
	for i in range(edges.size()):
		var edge = edges[i]
		var v1 = edge[0]
		var v2 = edge[1]
		if not vertex_to_edges.has(v1):
			vertex_to_edges[v1] = []
		vertex_to_edges[v1].append(i)
		if not vertex_to_edges.has(v2):
			vertex_to_edges[v2] = []
		vertex_to_edges[v2].append(i)
	
	# 因为是闭合多边形，可任意选择一个顶点
	var start_vertex = vertex_to_edges.keys()[0]
	var current_vertex = start_vertex
	var visited_edges = {}
	boundary.append(current_vertex)
	
	while true:
		var connected_edges = vertex_to_edges[current_vertex]
		
		# 找到一条未访问的边
		var next_edge_idx = -1
		for edge_idx in connected_edges:
			if not visited_edges.has(edge_idx):
				next_edge_idx = edge_idx
				break
		
		# 如果没有未访问的边，结束循环
		if next_edge_idx == -1:
			break
		
		# 标记这条边为已访问
		visited_edges[next_edge_idx] = true
		
		# 获取这条边的两个顶点
		var edge = edges[next_edge_idx]
		var v1 = edge[0]
		var v2 = edge[1]
		
		# 确定下一个顶点（不是当前顶点的那个）
		var next_vertex = v1 if v2 == current_vertex else v2
		
		# 添加到边界顶点列表
		boundary.append(next_vertex)
		
		# 移动到下一个顶点
		current_vertex = next_vertex
		
		# 如果回到起点，结束循环
		if current_vertex == start_vertex:
			break
	return boundary
