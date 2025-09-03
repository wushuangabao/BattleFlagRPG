# GridHelper.gd (Godot 4.x, GDScript)
# 这个类可以改造成 C++ 类（引擎核心类）以提高性能
class_name GridHelper

# 方向向量数组（顺时针排列）
const DIRECTIONS = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

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

# 获取步进方向（4邻域单位向量）
static func clamp_to_4dir(from_cell: Vector2i, target_cell: Vector2i) -> Vector2i:
	# 将任意目标格约束为距离为1的曼哈顿邻格
	var d = target_cell - from_cell
	var dx = 0 if d.x == 0 else (1 if d.x > 0 else -1)
	var dy = 0 if d.y == 0 else (1 if d.y > 0 else -1)

	# 只取一个轴，避免对角（优先较大的轴）
	if abs(d.x) >= abs(d.y):
		return from_cell + Vector2i(dx, 0)
	else:
		return from_cell + Vector2i(0, dy)

static func neighbors4(c: Vector2i) -> Array[Vector2i]:
	return [c + Vector2i(1,0), c + Vector2i(-1,0), c + Vector2i(0,1), c + Vector2i(0,-1)]

static func heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

static func a_star(start: Vector2i, goal: Vector2i, dir_start: Vector2i, is_walkable: Callable) -> Array[Vector2i]:
	var open: Array[Vector2i] = [start]
	var came := {} # node -> parent
	var g := { start: 0 } # 实际代价
	var f := { start: heuristic(start, goal) } # 估计总代价
	var angle_bias := { start: 0 } # 对齐偏好代价累计
	var last_dir := { start: dir_start } # 进入节点时的方向
	
	var sort_func = func(a, b): #候选点的优先级
		var fa = f.get(a, 1<<30)
		var fb = f.get(b, 1<<30)
		if fa != fb:
			return fa < fb
		var aa = angle_bias.get(a, 1<<30)
		var ab = angle_bias.get(b, 1<<30)
		if aa != ab:
			return aa < ab
		if last_dir.get(came[a], Vector2i.ZERO) == a - came[a]:
			return true
		return false
			
	while open.size() > 0:
		open.sort_custom(sort_func)
		var current: Vector2i = open[0]
		if current == goal:
			return _reconstruct(came, current)
		open.remove_at(0)
		var cur_to_goal: Vector2i = goal - current
		for n in neighbors4(current):
			if not is_walkable.call(n): continue
			var tentative_g = g[current] + 1
			var dir = clamp_to_4dir(current, n)
			var align_score = dir.x * cur_to_goal.x + dir.y * cur_to_goal.y # 对齐程度（越大越对齐）
			var prev_dir: Vector2i = last_dir.get(current, Vector2i.ZERO)
			var is_turn := (prev_dir != Vector2i.ZERO and dir != Vector2i.ZERO and prev_dir != dir) # 是否转向了
			var turn_penalty = 1 if is_turn else 0
			var tentative_angle = angle_bias.get(current, 0) - align_score * 2 + turn_penalty
			var better := false
			var old_g = g.get(n, 1<<30)
			if tentative_g < old_g:
				better = true
			elif tentative_g == old_g:
				# 同步长下，引入角度偏好+拐弯惩罚
				var old_angle = angle_bias.get(n, 1<<30)
				if tentative_angle < old_angle:
					better = true
			if better:
				came[n] = current
				g[n] = tentative_g
				f[n] = tentative_g + heuristic(n, goal)
				angle_bias[n] = tentative_angle
				last_dir[n] = dir
				if not n in open:
					open.append(n)
			#var tentative = g[current] + 1
			#if tentative < g.get(n, 1<<30):
				#came[n] = current
				#g[n] = tentative
				#f[n] = tentative + heuristic(n, goal)
				#if not n in open:
					#open.append(n)
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
