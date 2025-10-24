# GridHelper.gd (Godot 4.x, GDScript)
# 这个类可以改造成 C++ 类（引擎核心类）以提高性能
class_name GridHelper

# 方向向量数组（顺时针排列）
const DIRECTIONS = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

const ALIGN_WEIGHT := 0.02
const TURN_WEIGHT := 0.001

static var cell_size = Game.cell_pixel_size

static func pos2d_to_3d(v: Vector2) -> Vector3:
	return Vector3(v.x, 0, v.y)

static func to_cell(tilemap: TileMapLayer, world_pos: Vector2) -> Vector2i:
	var local = tilemap.to_local(world_pos)
	return tilemap.local_to_map(local)

# 单元格中心的世界坐标
static func to_world_center(tilemap: TileMapLayer, cell: Vector2i) -> Vector2:
	var local = tilemap.map_to_local(cell)
	return tilemap.to_global(local)

# 角色位置的世界坐标
static func to_world_player_2d(tilemap: TileMapLayer, cell: Vector2i) -> Vector2:
	var local = tilemap.map_to_local(cell)
	return tilemap.to_global(local) + Vector2(0, - cell_size.y * 0.2)

# 角色位置的世界坐标
static func to_world_player_3d(tilemap: TileMapLayer, cell: Vector2i) -> Vector3:
	var local = tilemap.map_to_local(cell)
	return Vector3(local.x / cell_size.x * Game.cell_world_size.x, 0, local.y / cell_size.y * Game.cell_world_size.y)

# 获取单元格某条边的两个顶点
static func get_edge_vertices(map: TileMapLayer, cell: Vector2i, direction: int) -> Array:
	var cell_origin = map.map_to_local(cell) - cell_size * 0.5
	match direction:
		0: # 上边
			return [cell_origin, 
					cell_origin + Vector2(cell_size.x, 0)]
		1: # 右边
			return [cell_origin + Vector2(cell_size.x, 0), 
					cell_origin + Vector2(cell_size.x, cell_size.y)]
		2: # 下边
			return [cell_origin + Vector2(cell_size.x, cell_size.y), 
					cell_origin + Vector2(0, cell_size.y)]
		3: # 左边
			return [cell_origin + Vector2(0, cell_size.y), 
					cell_origin]
	return []

#region 寻路算法

# 获取步进方向（4 邻域单位向量，优先较大的轴）
static func clamp_to_4dir(from_cell: Vector2i, target_cell: Vector2i) -> Vector2i:
	var d = target_cell - from_cell
	var dx = 0 if d.x == 0 else (1 if d.x > 0 else -1)
	var dy = 0 if d.y == 0 else (1 if d.y > 0 else -1)
	if abs(d.x) >= abs(d.y):
		return Vector2i(dx, 0)
	else:
		return Vector2i(0, dy)

static func neighbors4(c: Vector2i) -> Array[Vector2i]:
	return [c + Vector2i(1,0), c + Vector2i(-1,0), c + Vector2i(0,1), c + Vector2i(0,-1)]

static func heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

static func a_star(start: Vector2i, goal: Vector2i, dir_start: Vector2i, is_walkable: Callable) -> Array[Vector2i]:
	var dir_to_goal: Vector2i = goal - start
	if dir_to_goal == Vector2i.ZERO:
		return []

	var open: Array[Vector2i] = [start]
	var came := {} # node -> parent
	var g := { start: 0 } # 实际代价
	var f := { start: heuristic(start, goal) } # 估计总代价
	var angle_bias := { start: 0.0 } # 对齐偏好代价累计（浮点）
	var last_dir := { start: dir_start } # 进入节点时的方向
	var closed := {} # 关闭集：已处理节点
	
	var sort_func = func(a, b): #候选点的优先级
		var fa = f.get(a, 1<<30)
		var fb = f.get(b, 1<<30)
		if fa != fb:
			return fa < fb
		var aa = angle_bias.get(a, 1e9)
		var ab = angle_bias.get(b, 1e9)
		if aa != ab:
			return aa < ab
		var came_a: Vector2i = came.get(a, a)
		var came_b: Vector2i = came.get(b, b)
		var step_a: Vector2i = a - came_a
		var step_b: Vector2i = b - came_b
		var dir_a: Vector2i = last_dir.get(came_a, Vector2i.ZERO)
		var dir_b: Vector2i = last_dir.get(came_b, Vector2i.ZERO)
		var straight_a := (dir_a == step_a)
		var straight_b := (dir_b == step_b)
		if straight_a != straight_b:
			return straight_a
		return false
			
	while open.size() > 0:
		open.sort_custom(sort_func)
		var current: Vector2i = open[0]
		if current == goal:
			return _reconstruct(came, current)
		open.remove_at(0)
		closed[current] = true
		for n in neighbors4(current):
			if not is_walkable.call(n): continue
			var tentative_g = g[current] + 1
			dir_to_goal = goal - n
			var align_cos: float = 0.0
			if dir_to_goal != Vector2i.ZERO:
				var dir_to_goal_norm: Vector2 = Vector2(dir_to_goal).normalized()
				var dir_from_start_norm: Vector2 = Vector2(n - start).normalized()
				align_cos = dir_from_start_norm.dot(dir_to_goal_norm)
			var dir: Vector2i = clamp_to_4dir(current, n)
			var prev_dir: Vector2i = last_dir.get(current, Vector2i.ZERO)
			var is_turn := (prev_dir != Vector2i.ZERO and dir != Vector2i.ZERO and prev_dir != dir)
			var turn_penalty: float = 0.0
			if current != start:
				turn_penalty = 0.0 if is_turn else TURN_WEIGHT
			else:
				turn_penalty = TURN_WEIGHT if is_turn else 0.0
			var tentative_angle: float = angle_bias.get(current, 0.0) - align_cos * ALIGN_WEIGHT + turn_penalty
			var better := false
			var old_g = g.get(n, 1<<30)
			if tentative_g < old_g:
				better = true
			elif tentative_g == old_g:
				# 同步长下，引入角度偏好+拐弯惩罚
				var old_angle = angle_bias.get(n, 1e9)
				if tentative_angle < old_angle:
					better = true
			if better:
				came[n] = current
				g[n] = tentative_g
				f[n] = tentative_g + heuristic(n, goal)
				angle_bias[n] = tentative_angle
				last_dir[n] = dir
				if closed.has(n):
					closed.erase(n)
				if not n in open:
					open.append(n)
	return []

static func _reconstruct(came: Dictionary, cur: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [cur]
	while came.has(cur):
		cur = came[cur]
		path.push_front(cur)
	return path

# 计算在 max_steps 内可达的所有格以及达到该格的步数成本。
static func movement_range(origin: Vector2i, max_steps: int, is_walkable: Callable) -> Dictionary:
	var dist := { origin: 0 }
	var queue: Array[Vector2i] = [origin]
	if max_steps == -1:
		max_steps = 1>>30
	while queue.size() > 0:
		var cur = queue.pop_front()
		for n in neighbors4(cur):
			if not is_walkable.call(n): continue
			var nd = dist[cur] + 1
			if nd <= max_steps and nd < dist.get(n, 1<<30):
				dist[n] = nd
				queue.append(n)
	return dist # Dictionary cell->steps

#endregion

#region 技能范围

# 返回所有满足 |dx| + |dy| = r 且 check_func(pos) == true 的格子
static func manhattan_ring(center: Vector2i, r: int, check_func: Callable) -> Array[Vector2i]:
	if r < 0:
		return []
	if r == 0:
		return [center]
	var result: Array[Vector2i] = []
	for dx in range(-r, r + 1):
		var dy := r - absi(dx)
		if dy == 0:
			var pos := center + Vector2i(dx, 0)
			if check_func.call(pos):
				result.append(pos)
		else:
			var pos := center + Vector2i(dx, dy)
			if check_func.call(pos):
				result.append(pos)
			pos = center + Vector2i(dx, -dy)
			if check_func.call(pos):
				result.append(pos)
	return result

# 返回所有满足 |dx| + |dy| ≤ r 且 check_func(pos) == true 的格子
static func manhattan_area(center: Vector2i, r: int, check_func: Callable) -> Array[Vector2i]:
	if r < 0:
		return []
	var result: Array[Vector2i] = []
	for dx in range(-r, r + 1):
		var max_dy := r - absi(dx)
		var base := Vector2i(center.x + dx, center.y)
		for dy in range(-max_dy, max_dy + 1):
			var pos := base + Vector2i(0, dy)
			if check_func.call(pos):
				result.append(pos)
	return result

# 生成从 origin 到 target 的离散网格路径，并筛选出到 origin 的曼哈顿距离在 [d_inner, d_outer] 区间内的所有点
static func path_points_in_manhattan_ring(origin: Vector2i, target: Vector2i, dir_start: Vector2i, d_inner: int, d_outer: int, check_func: Callable, is_blockable: bool) -> Array[Vector2i]:
	if d_outer < d_inner or d_inner < 0:
		push_error("path_points_in_manhattan_ring：错误的参数！")
		return []
	var path: PackedVector2Array = Utils.a_star_no_check(origin, target, dir_start)
	var result: Array[Vector2i] = []
	for i in range(path.size()):
		var c: Vector2i = Vector2i(path[i].round())
		var manhattan := absi(c.x - origin.x) + absi(c.y - origin.y)
		if manhattan >= d_inner and manhattan <= d_outer and check_func.call(c):
			result.append(c)
			if is_blockable and Game.g_combat and Game.g_combat.get_actor_on_cell(c) != null:
				return result
	return result

# 生成从 origin 开始、经过 target，终点到 origin 的曼哈顿距离为 d_outer 的路径，并筛选 [d_inner, d_outer] 的点
static func path_via_target_to_manhattan_ring(origin: Vector2i, target: Vector2i, dir_start: Vector2i, d_inner: int, d_outer: int, check_func: Callable, is_blockable: bool) -> Array[Vector2i]:
	if d_outer < d_inner or d_inner < 0:
		push_error("path_via_target_to_manhattan_ring：错误的参数！")
		return []
	# 段1：origin -> target
	var path1: PackedVector2Array = Utils.a_star_no_check(origin, target, dir_start)
	# 计算终点（终点到 origin 的曼哈顿距离为 d_outer），沿 origin→target 的射线按比例分配 X/Y
	var md_target := absi(target.x - origin.x) + absi(target.y - origin.y)
	var end: Vector2i = target
	if md_target != d_outer:
		var d: Vector2i = target - origin
		var ax := absi(d.x)
		var ay := absi(d.y)
		var sum := ax + ay
		if sum == 0:
			# origin == target，使用 dir_start 方向延伸
			var sx := 0 if dir_start.x == 0 else (1 if dir_start.x > 0 else -1)
			var sy := 0 if dir_start.y == 0 else (1 if dir_start.y > 0 else -1)
			var steps_x_total := int(round(d_outer * absi(dir_start.x)))
			var steps_y_total := d_outer - steps_x_total
			end = origin + Vector2i(sx * steps_x_total, sy * steps_y_total)
		else:
			var sx := 0 if d.x == 0 else (1 if d.x > 0 else -1)
			var sy := 0 if d.y == 0 else (1 if d.y > 0 else -1)
			var steps_x_total := int(round(float(d_outer) * float(ax) / float(sum)))
			var steps_y_total := d_outer - steps_x_total
			end = origin + Vector2i(sx * steps_x_total, sy * steps_y_total)
	# 段2：target -> end
	var dir_start_ext: Vector2i = clamp_to_4dir(target, end)
	if dir_start_ext == Vector2i.ZERO:
		dir_start_ext = dir_start if dir_start != Vector2i.ZERO else Vector2i(1, 0)
	var path2: PackedVector2Array = Utils.a_star_no_check(target, end, dir_start_ext)
	# 合并路径并筛选 [d_inner, d_outer]
	var result: Array[Vector2i] = []
	for i in range(path1.size()):
		var c: Vector2i = Vector2i(path1[i].round())
		var manhattan := absi(c.x - origin.x) + absi(c.y - origin.y)
		if manhattan >= d_inner and manhattan <= d_outer and check_func.call(c):
			result.append(c)
			if is_blockable and Game.g_combat and Game.g_combat.get_actor_on_cell(c) != null:
				return result
	var start_index := 1 if path2.size() > 0 else 0
	for i in range(start_index, path2.size()):
		var c: Vector2i = Vector2i(path2[i].round())
		var manhattan := absi(c.x - origin.x) + absi(c.y - origin.y)
		if manhattan >= d_inner and manhattan <= d_outer and check_func.call(c):
			if result.size() == 0 or result[result.size() - 1] != c:
				result.append(c)
			if is_blockable and Game.g_combat and Game.g_combat.get_actor_on_cell(c) != null:
				return result
	return result

# 计算技能范围，check_func 是一个 func(c: Vector2i) -> bool
static func get_skill_area_cells(area_data: SkillAreaShape, origin: Vector2i, target: Vector2i, dir_start: Vector2i, check_func: Callable) -> Array[Vector2i]:
	match area_data.shape_type:
		SkillAreaShape.ShapeType.Single:
			if area_data.is_blockable:
				return [origin] #todo
			else:
				if area_data.target_range == 0:
					return [target]
				else:
					return manhattan_area(target, area_data.target_range, check_func)
		SkillAreaShape.ShapeType.Line:
				return path_via_target_to_manhattan_ring(origin, target, dir_start, area_data.d_inner, area_data.d_outer, check_func, area_data.is_blockable)
		SkillAreaShape.ShapeType.Ring:
			var res = manhattan_ring(target, area_data.d_outer, check_func)
			for i in range(area_data.d_inner, area_data.d_outer):
				res.append_array(manhattan_ring(target, i, check_func))
			return res
	return []

#endregion
