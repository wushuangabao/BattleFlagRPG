# GridHelper.gd (Godot 4.x, GDScript)
# 这个类可以改造成 C++ 类（引擎核心类）以提高性能
class_name GridHelper

static var cell_size: Vector2i = Vector2i(64, 64)

static func to_cell(tilemap: TileMapLayer, world_pos: Vector2) -> Vector2i:
	var local = tilemap.to_local(world_pos)
	return tilemap.local_to_map(local)

static func to_world_center(tilemap: TileMapLayer, cell: Vector2i) -> Vector2:
	var local = tilemap.map_to_local(cell)
	return tilemap.to_global(local)

static func to_world_player(tilemap: TileMapLayer, cell: Vector2i) -> Vector2:
	var local = tilemap.map_to_local(cell)
	return tilemap.to_global(local) + Vector2(0, - cell_size.y * 0.2)

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

static func a_star(start: Vector2i, goal: Vector2i, is_walkable: Callable) -> Array[Vector2i]:
	var open: Array[Vector2i] = [start]
	var came := {}
	var g := { start: 0 }
	var f := { start: heuristic(start, goal) }
	while open.size() > 0:
		open.sort_custom(func(a,b): return f.get(a, 1<<30) < f.get(b, 1<<30))
		var current: Vector2i = open[0]
		if current == goal:
			return _reconstruct(came, current)
		open.remove_at(0)
		for n in neighbors4(current):
			if not is_walkable.call(n): continue
			var tentative = g[current] + 1
			if tentative < g.get(n, 1<<30):
				came[n] = current
				g[n] = tentative
				f[n] = tentative + heuristic(n, goal)
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
