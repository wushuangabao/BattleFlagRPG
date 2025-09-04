class_name BattleScene
extends Node3D

@export var board_plane_path: NodePath
@export var camera_path: NodePath
@export var subviewport_path: NodePath
@export var unit_template: PackedScene

# 是否在SubViewport背景透明（若想保留透明区域）
@export var transparent_bg := true

@onready var camera := get_node(camera_path) as Camera3D_movable
@onready var board_plane := get_node(board_plane_path) as MeshInstance3D
@onready var subvp := get_node(subviewport_path) as BattleMapContainer   # 战斗地图的容器

var _cur_unit : UnitBase3D = null
var controller : BattleController = null
var ground_layer : Ground
var flag_layer   : FlagLayer

# 地图行列数（用于计算SubViewport size与Plane尺寸）
var map_cols: int
var map_rows: int

var cell_pixel_size = Game.cell_pixel_size
var cell_world_size = Game.cell_world_size

func load_battle_map(map_name: String) -> void:
	subvp.loadScene_battleMap(map_name)
	var map_root = subvp.get_child(0).get_child(0)
	ground_layer = map_root.get_child(0)           # CanvasLayer/TilemapRoot2D/Ground
	flag_layer   = map_root.get_child(1)           # CanvasLayer/TilemapRoot2D/Flag
	var dim = ground_layer.get_tilemap_dimensions()
	map_cols = dim.x
	map_rows = dim.y
	_configure_subviewport()
	_configure_board_plane()
	_hook_subviewport_texture_to_plane()
	# 如果地图是静态的，可只刷新一次
	subvp.render_target_update_mode = SubViewport.UPDATE_ONCE

func add_unit_to(actor: ActorController, cell: Vector2i, islook:= false) -> UnitBase3D:
	if ground_layer == null:
		push_error("add unit to Nil ground!")
	var new_unit = unit_template.instantiate() as UnitBase3D
	new_unit.set_actor(actor)
	new_unit.map = ground_layer
	new_unit.set_cur_cell(cell)
	if islook:
		new_unit.ready.connect(func():
			camera.set_target_immediately(new_unit)
			print("on new unit ready"))
	add_child(new_unit)
	if islook:
		_cur_unit = new_unit
	return new_unit

# 只调用一次，除非手动 request_ready
# 所有子节点都已经添加到场景树后，才会调用
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	controller = Game.g_combat
	controller.set_scene_node(self)
	controller.on_battle_start()

# 每次切到战斗场景都会调用
# 此时子节点还未添加
func _enter_tree() -> void:
	if controller == null:
		return
	controller.on_battle_start()

func _configure_board_plane() -> void:
	var plane := board_plane.mesh
	if plane is PlaneMesh:
		plane.size = Vector2(map_cols * cell_world_size.x, map_rows * cell_world_size.y)
		board_plane.position = Vector3(plane.size.x * 0.5, 0.0, plane.size.y * 0.5)
		board_plane.mesh = plane

func _configure_subviewport() -> void:
	subvp.size = Vector2i(map_cols * cell_pixel_size.x, map_rows * cell_pixel_size.y)
	subvp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	# 更新模式：调试期实时，发布期改为 UPDATE_ONCE 并在需要时手动触发
	if Game.Debug == 1:
		subvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		subvp.render_target_update_mode = SubViewport.UPDATE_ONCE

func _hook_subviewport_texture_to_plane() -> void:
	var tex := subvp.get_texture()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	# 无光照
	# mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# 材质透明开关依然需要，才能正确显示 SubViewport 的 alpha
	if transparent_bg:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	board_plane.set_surface_override_material(0, mat)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var dir = camera.project_ray_normal(mouse_pos)
		# 与 y=0 平面求交
		if absf(dir.y) < 1e-6: # 射线几乎平行于地面
			return
		var t = -from.y / dir.y
		if t <= 0.0: # 交点在摄像机背后
			return
		var hit = from + dir * t
		if Game.Debug == 1:
			#draw_debug_ray(Vector3(from.x, from.y - 0.01, from.z), hit)
			# 将世界坐标映射到格子坐标
			print("Clicked pos: ", hit.x, ", ",  hit.z)
		var cell = ground_layer.local_to_map(Vector2(hit.x * cell_pixel_size.x, hit.z * cell_pixel_size.y))
		_on_cell_clicked(cell)

func _on_cell_clicked(cell: Vector2i) -> void:
	if Game.Debug == 1:
		print("Clicked cell: ", cell)
	ground_layer.highlight_cell(cell, _cur_unit.set_target_cell(cell))
	# 由于我们把SubViewport设置为UPDATE_ONCE，这里需要触发一次刷新：
	subvp.render_target_update_mode = SubViewport.UPDATE_ONCE

func draw_debug_ray(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	var length := dir.length()
	if length <= 0.0001:
		return
	
	# 生成可见的圆柱体
	var line := MeshInstance3D.new()
	var mat  := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mat.emission_enabled = true
	mat.emission = Color.RED
	line.material_override = mat

	# 用 ImmediateMesh 画一条线段
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(from)
	im.surface_add_vertex(from + dir * 0.8)
	im.surface_end()
	line.mesh = im

	add_child(line)

	# 延迟清理
	await get_tree().create_timer(2.0).timeout
	line.queue_free()
