extends Node3D

# 可在编辑器中拖拽赋值，或用 @onready 路径获取
@export var board_plane_path: NodePath
@export var camera_path: NodePath
@export var subviewport_path: NodePath
@export var tilemap_root2d_path: NodePath
@export var ground_layer_path: NodePath # TileMapLayer
@export var overlay_layer_path: NodePath # 可选，高亮用

# 每格在3D世界中的大小（与PlaneMesh尺寸一致）
@export var cell_world_size: Vector2 = Vector2(1.0, 1.0) # x 对应世界X，y对应世界Z
# TileMap中每格的像素尺寸（与TileSet一致）
@export var cell_pixel_size: Vector2i = Vector2i(64, 64)
# 地图行列数（用于计算SubViewport size与Plane尺寸）
@export var map_cols: int = 16
@export var map_rows: int = 12

# 是否在SubViewport背景透明（若想保留透明区域）
@export var transparent_bg := true
# 是否使用无光照卡通效果（像素图常用）
@export var unshaded := true

@onready var camera := get_node(camera_path) as Camera3D
@onready var board_plane := get_node(board_plane_path) as MeshInstance3D
@onready var subvp := get_node(subviewport_path) as SubViewport
@onready var tilemap_root2d := get_node(tilemap_root2d_path) as Node2D
@onready var ground_layer := get_node_or_null(ground_layer_path) as TileMapLayer
@onready var overlay_layer := get_node_or_null(overlay_layer_path) as TileMapLayer

func _ready() -> void:
	_configure_subviewport()
	_configure_tilemap_canvas()
	_configure_board_plane()
	_hook_subviewport_texture_to_plane()
	# 如果地图是静态的，可只刷新一次
	subvp.render_target_update_mode = SubViewport.UPDATE_ONCE
	# 调整相机以看到全部棋盘（可根据你的需求微调）
	_frame_camera_to_board()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _configure_tilemap_canvas() -> void:
	# 将TileMap原点放在(0,0)，使其像素与SubViewport对齐
	tilemap_root2d.position = Vector2.ZERO
	# tilemap.position = Vector2.ZERO
	if ground_layer:
		ground_layer.position = Vector2.ZERO
	if overlay_layer:
		overlay_layer.position = Vector2.ZERO
	# 可选：在启动时填充一个简单图案，验证渲染是否成功
	_debug_fill_ground_if_empty()

func _configure_board_plane() -> void:
	var plane := board_plane.mesh
	if plane is PlaneMesh:
		plane.size = Vector2(map_cols * cell_world_size.x, map_rows * cell_world_size.y)
		board_plane.mesh = plane
	var half_w = 0.5 * map_cols * cell_world_size.x
	var half_h = 0.5 * map_rows * cell_world_size.y
	board_plane.transform.origin = Vector3(half_w, 0.0, half_h)

# 如果你之前有 @export var transparent_bg := true，保留这个变量即可
# 用它来决定是否清为透明背景
func _configure_subviewport() -> void:
	# 尺寸
	#subvp.size_2d = Vector2i(map_cols * cell_pixel_size.x, map_rows * cell_pixel_size.y)
	# 更新模式：调试期实时，发布期改为 UPDATE_ONCE 并在需要时手动触发
	#subvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# 背景处理（替代 transparent_bg）
	if transparent_bg:
		subvp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	else:
		subvp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

func _hook_subviewport_texture_to_plane() -> void:
	var tex := subvp.get_texture()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	# 材质透明开关依然需要，才能正确显示 SubViewport 的 alpha
	if transparent_bg:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	board_plane.set_surface_override_material(0, mat)

func _frame_camera_to_board() -> void:
	# 一个简单的等距俯视设置：45°斜角，居中看向棋盘
	# 你也可以改为正交相机
	var board_center = Vector3(map_cols * cell_world_size.x * 0.5, 0.0, map_rows * cell_world_size.y * 0.5)
	var radius = max(map_cols * cell_world_size.x, map_rows * cell_world_size.y)
	var height = radius
	var back = radius
	camera.transform.origin = board_center + Vector3(-back, height, -back) # 斜上后方
	camera.look_at(board_center, Vector3.UP)
	camera.fov = 45.0

func _debug_fill_ground_if_empty() -> void:
	if not ground_layer:
		return
	# 如果没有任何cell，则填充棋盘测试
	var any_cell := false
	for y in range(map_rows):
		for x in range(map_cols):
			if ground_layer.get_cell_source_id(Vector2i(x, y)) != -1:
				any_cell = true
				break
		if any_cell: break
	if not any_cell:
		# 用TileSet中的第一个Tile填充（确保TileSet中source_id=0存在）
		for y in range(map_rows):
			for x in range(map_cols):
				ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0)) # source_id=0, atlas_coord=(0,0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var dir = camera.project_ray_normal(mouse_pos)
		# 与 y=0 平面求交
		if absf(dir.y) < 1e-6:
			return
		var t = -from.y / dir.y
		if t <= 0.0:
			return
		var hit = from + dir * t
		# 将世界坐标映射到格子坐标。注意：我们让棋盘左下是(0,0)，plane中心在(half_w,half_h)
		var cell_x = int(floor(hit.x / cell_world_size.x))
		var cell_y = int(floor(hit.z / cell_world_size.y))
		if _in_bounds(cell_x, cell_y):
			_on_cell_clicked(Vector2i(cell_x, cell_y))

func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < map_cols and y < map_rows

func _on_cell_clicked(cell: Vector2i) -> void:
	print("Clicked cell: ", cell)
	# 可选：在overlay层高亮点击的格子
	if overlay_layer:
		overlay_layer.clear()
		# 假设TileSet里有一个高亮tile，source_id=1, atlas=(0,0)。没有的话也可用 canvas drawing。
		overlay_layer.set_cell(cell, 1, Vector2i(0, 0))
		# 由于我们把SubViewport设置为UPDATE_ONCE，这里需要触发一次刷新：
		subvp.render_target_update_mode = SubViewport.UPDATE_ONCE
