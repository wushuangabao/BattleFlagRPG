extends Node2D
class_name OverLay

var grid: GroundLayer # 指向 GroundLayer 类型的父节点

func _draw():
	# 可达范围
	var cells: Array[Vector2i] = []
	for cell in grid.reachable_map.keys():
		# 注释掉的 3 行是直接填充每格的矩形。目前不这样做，目前要绘制可达范围的边界
		# var center: Vector2 = grid.map_to_local(cell)
		# var top_left: Vector2 = center - Vector2(GridHelper.cell_size) * 0.5
		# draw_rect(Rect2(top_left, Vector2(GridHelper.cell_size)), grid.color_range, false, 2.0)
		cells.push_back(cell)
	_draw_boundary(cells, grid.color_range_border, 2.0)

	# 技能范围
	if grid.chose_area_cells.size() >= 1:
		for c in grid.chose_area_cells:
			var center: Vector2 = grid.map_to_local(c)
			var top_left: Vector2 = center - Vector2(GridHelper.cell_size) * 0.5
			draw_rect(Rect2(top_left, Vector2(GridHelper.cell_size)), grid.color_range_chose)
	if grid.skill_area_cells.size() >= 1:
		for c in grid.skill_area_cells:
			var center: Vector2 = grid.map_to_local(c)
			var top_left: Vector2 = center - Vector2(GridHelper.cell_size) * 0.5
			draw_rect(Rect2(top_left, Vector2(GridHelper.cell_size)), grid.color_range_skill)

	# 路径
	var actor = null
	if grid.path_cells.size() > 1:
		var points: PackedVector2Array = []
		for c in grid.path_cells:
			points.append(grid.map_to_local(c))
		if grid.flag_layer == null:
			for i in range(points.size() - 1):
				draw_line(points[i], points[i + 1], grid.color_path_line, grid.path_line_width)
			for p in points:
				draw_circle(p, GridHelper.cell_size.x * 0.12, grid.color_path_node)
			return
		actor = Game.g_combat.get_actor_on_cell(grid.path_cells[0])
		if actor:
			_draw_path_with_direction(actor, points)
	
	# 高亮格子
	for k in grid.hightlight_cell_map:
		var c = grid.hightlight_cell_map[k]
		if c.x >= 0 and c.y >= 0:
			var center: Vector2 = grid.map_to_local(c)
			if grid.color_hgihtlight_rect.has(k):
				var top_left: Vector2 = center - Vector2(GridHelper.cell_size) * 0.5
				draw_rect(Rect2(top_left, Vector2(GridHelper.cell_size)), grid.color_hgihtlight_rect[k], true)
			elif grid.color_hgihtlight_circle.has(k):
				draw_circle(center, GridHelper.cell_size.x * 0.501, grid.color_hgihtlight_circle[k])
			elif grid.color_hgihtlight_circle_border.has(k):
				draw_circle(center, GridHelper.cell_size.x * 0.51, grid.color_hgihtlight_circle_border[k], false, 1.5)

	# 检查是否有转向预览
	var current_dir
	if grid.preview_facing_actor:
		current_dir = grid.preview_facing_actor.get_facing_vector()
		if Vector2(current_dir).is_equal_approx(grid.preview_facing_dir):
			grid.clear_preview_facing()

	# 朝向指示器（三角形）
	if grid.flag_layer and grid.facing_indicator_map.size() > 0:
		for a in grid.facing_indicator_map:
			if a != actor and a != grid.preview_facing_actor: # 绘制移动路径、转向预览时，不显示朝向
				if a.get_state() == ActorController.ActorState.Idle:
					_draw_facing_indicator(a)

	# 转向预览
	if grid.flag_layer and grid.preview_facing_actor and grid.preview_facing_dir != Vector2.ZERO:
		var a_prev: ActorController = grid.preview_facing_actor
		var sz_prev: float = GridHelper.cell_size.x * grid.facing_indicator_size_ratio
		var center: Vector2 = grid.map_to_local(a_prev.base3d.get_cur_cell())
		var fill_col: Color = grid.facing_indicator_player_color if grid.flag_layer.is_player_team(a_prev.team_id) else grid.facing_indicator_enemy_color
		var ret_cur = _draw_triangle(center, current_dir, sz_prev, null, null, 0.5, sz_prev * 0.8)
		var poly_old = PackedVector2Array([ret_cur[1], ret_cur[2], ret_cur[3]])
		var ret_prev = _draw_triangle(center, grid.preview_facing_dir, sz_prev, fill_col, null, 0.5, sz_prev * 0.8)
		var poly_new = PackedVector2Array([ret_prev[1], ret_prev[2], ret_prev[3]])
		var o_minus_n: Array = Geometry2D.clip_polygons(poly_old, poly_new)
		if o_minus_n.size() > 0:
			fill_col.a *= 0.5
			draw_colored_polygon(o_minus_n[0], fill_col)

# 绘制闭合的多边形轮廓
func _draw_boundary(cells: Array[Vector2i], color: Color, width: float) -> void:
	if cells.size() > 1:
		var cell_set = {}
		for cell in cells:
			cell_set[cell] = true
		for cell in cells:
			for i in range(4):
				var dir = GridHelper.DIRECTIONS[i]
				var neighbor = cell + dir
				# 如果邻居不在集合中，则这条边是边界
				if not cell_set.has(neighbor):
					var vertices = GridHelper.get_edge_vertices(grid, cell, i)
					# 绘制这条边
					draw_line(vertices[0], vertices[1], color, width)
		# 下面这个连接成多边形的方法在“有洞”的情况下不好使
		# 收集多边形的顶点
		# var edges = []
		# for cell in cells:
		# 	for i in range(4):
		# 		var dir = GridHelper.DIRECTIONS[i]
		# 		var neighbor = cell + dir
		# 		# 如果邻居不在集合中，则这条边是边界
		# 		if not cell_set.has(neighbor):
		# 			var vertices = GridHelper.get_edge_vertices(grid, cell, i)
		# 			edges.append(vertices)
		# if edges.size() == 0:
		# 	return
		# var boundary = connect_edges(edges)
		# if boundary.size() >= 4:
		# 	draw_polyline(PackedVector2Array(boundary), color, width)
	
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

func _draw_path_with_direction(actor: ActorController, points: PackedVector2Array) -> void:
	var col: Color = grid.facing_indicator_team_colors[actor.team_id]
	# 绘制起点箭头
	var curr_cell := grid.path_cells[0]
	var next_cell := grid.path_cells[1]
	var center2d: Vector2 = grid.map_to_local(curr_cell)
	var dir: Vector2 = Vector2(next_cell - curr_cell)
	if dir == Vector2.ZERO:
		return
	var size: float = GridHelper.cell_size.x * grid.facing_indicator_size_ratio_selected
	points[0] = _draw_triangle(center2d, dir, size, col)[1]
	# 绘制终点箭头
	var last_i = grid.path_cells.size() - 1
	curr_cell = grid.path_cells[last_i]
	var prev_cell: Vector2i = grid.path_cells[last_i - 1]
	center2d = grid.map_to_local(curr_cell)
	dir = Vector2(curr_cell - prev_cell)
	if dir == Vector2.ZERO:
		return
	size = GridHelper.cell_size.x * grid.facing_indicator_size_ratio
	points[last_i] = _draw_triangle(center2d, dir, size, col, null, grid.facing_indicator_size_ratio * 0.35, size * 0.75)[0]
	# 绘制路径
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], col, grid.path_line_width)

func _draw_facing_indicator(actor: ActorController) -> void:
	var item = grid.facing_indicator_map[actor]
	if not item.has("cell") or not item.has("dir"):
		return
	var cell: Vector2i = item["cell"]
	var dir: Vector2 = (item["dir"] as Vector2)
	if dir == Vector2.ZERO:
		return
	# 颜色按队伍区分
	var is_player_team := grid.flag_layer.is_player_team(actor.team_id)
	var fill_col: Color = grid.facing_indicator_player_color if is_player_team else grid.facing_indicator_enemy_color
	var border_col: Color = grid.facing_indicator_team_colors[actor.team_id]
	var center2d: Vector2 = grid.map_to_local(cell)
	var size: float
	var cur_cell := grid.hightlight_cell_map[&"current_actor"]
	if cur_cell == cell:
		size = GridHelper.cell_size.x * grid.facing_indicator_size_ratio_selected
	else:
		size = GridHelper.cell_size.x * grid.facing_indicator_size_ratio
	_draw_triangle(center2d, dir, size, fill_col, border_col)

func _draw_triangle(center2d: Vector2, dir: Vector2, size: float, fill_col = null, border_col = null, offset: float = 0.0, half_w = null) -> Array[Vector2]:
	var dir_n := dir.normalized()
	var perp := Vector2(-dir_n.y, dir_n.x)
	var base_center = center2d + dir_n * size * (offset - 0.25)
	var apex = base_center + dir_n * size * 0.8
	if half_w == null:
		half_w = size * 0.5
	var p1 = base_center + perp * half_w
	var p2 = base_center - perp * half_w
	# 填充
	if fill_col:
		draw_colored_polygon(PackedVector2Array([apex, p1, p2]), fill_col)
	# 描边
	if border_col:
		draw_line(apex, p1, border_col, grid.facing_indicator_border_width)
		draw_line(p1, p2, border_col, grid.facing_indicator_border_width)
		draw_line(p2, apex, border_col, grid.facing_indicator_border_width)
	# 返回三角形的基点
	return [base_center, apex, p1, p2]
