# GridHelper.gd (Godot 4.x, GDScript)
extends Node
class_name GridHelper

static var cell_size: Vector2i = Vector2i(64, 64)

static func to_cell(tilemap: TileMapLayer, world_pos: Vector2) -> Vector2i:
	var local = tilemap.to_local(world_pos)
	return tilemap.local_to_map(local)

static func to_world_center(tilemap: TileMapLayer, cell: Vector2i) -> Vector2:
	var local = tilemap.map_to_local(cell)
	return tilemap.to_global(local) + Vector2(0, - cell_size.y * 0.2)

static func clamp_to_4dir(from_cell: Vector2i, target_cell: Vector2i) -> Vector2i:
	# 将任意目标格约束为距离为1的曼哈顿邻格
	var d = target_cell - from_cell
	var dx = 0
	if d.x != 0:
		if d.x > 0:
			d.x = 1
		else:
			d.x = -1
	var dy = 0
	if d.y != 0:
		if d.y > 0:
			d.y = 1
		else:
			d.y = -1
	# 只取一个轴，避免对角（优先较大的轴）
	if abs(d.x) >= abs(d.y):
		return from_cell + Vector2i(dx, 0)
	else:
		return from_cell + Vector2i(0, dy)

static func neighbors4(c: Vector2i) -> Array[Vector2i]:
	return [c + Vector2i(1,0), c + Vector2i(-1,0), c + Vector2i(0,1), c + Vector2i(0,-1)]
