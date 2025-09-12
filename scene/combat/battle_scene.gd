class_name BattleScene
extends Node3D

@export var board_plane_path: NodePath
@export var camera_path: NodePath
@export var subviewport_path: NodePath
@export var timeline_path: NodePath
@export var turn_contr_path : NodePath

# 是否在SubViewport背景透明（若想保留透明区域）
@export var transparent_bg := true

@onready var camera := get_node(camera_path) as Camera3D_movable
@onready var board_plane := get_node(board_plane_path) as MeshInstance3D
@onready var subvp := get_node(subviewport_path) as BattleMapContainer   # 战斗地图的容器
@onready var timeline := get_node(timeline_path) as TimelineController
@onready var turn_controller := get_node(turn_contr_path) as TurnController

var _cur_unit : UnitBase3D = null
var my_system : BattleSystem = null
var ground_layer : Ground
var flag_layer   : FlagLayer

# 地图行列数（用于计算SubViewport size与Plane尺寸）
var map_cols: int
var map_rows: int

var cell_pixel_size = Game.cell_pixel_size
var cell_world_size = Game.cell_world_size

func load_battle_map(map_name: String) -> bool:
	var new_node = await subvp.loadScene_battleMap(map_name)
	if new_node == null:
		return false
	var map_root = subvp.get_child(0).get_child(1)
	ground_layer = map_root.get_child(0)           # CanvasLayer/TilemapRoot2D/Ground
	flag_layer   = map_root.get_child(1)           # CanvasLayer/TilemapRoot2D/Flag
	var dim = ground_layer.get_tilemap_dimensions()
	map_cols = dim.x
	map_rows = dim.y
	_configure_subviewport()
	_configure_board_plane()
	_hook_subviewport_texture_to_plane()
	subvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	print("战斗地图加载完毕 - ", subvp._current_scene)
	return true

func add_unit_to(unit_template: PackedScene, cell: Vector2i, islook:= false) -> UnitBase3D:
	if ground_layer == null:
		push_error("add unit to Nil ground!")
	var new_unit = unit_template.instantiate() as UnitBase3D
	new_unit.map = ground_layer
	new_unit.set_cur_cell(cell)
	if islook:
		_cur_unit = new_unit
		new_unit.initialized.connect(_on_cur_actor_initialized)
	add_child(new_unit)
	return new_unit

func _on_cur_actor_initialized(unit_node: UnitBase3D) -> void:
	if unit_node != _cur_unit:
		return
	camera.set_target_immediately(_cur_unit)

# 设置高亮
func select_preview_actor(actor: ActorController) -> void:
	if actor:
		for a in my_system.get_actors():
			if a != actor:
				a.anim_player.highlight_off()
			else:
				a.anim_player.highlight_on()
		if _cur_unit != actor:
			camera.set_target_gradually(actor.base3d)

# 取消高亮
func release_preview_actor(actor: ActorController) -> void:
	if actor and actor is ActorController:
		if _cur_unit and Game.g_combat.get_battle_state() == BattleSystem.BattleState.ActorIdle:
			select_preview_actor(_cur_unit.actor)
			camera.set_target_gradually(_cur_unit)
		else:
			_release_preview_actor()

func _release_preview_actor() -> void:
	for a in my_system.get_actors():
		a.anim_player.highlight_on()

# 选取角色（准备做动作）
func select_current_actor(actor: ActorController) -> void:
	ground_layer.clear_on_change_cur_actor_to(actor)
	_cur_unit = actor.base3d
	_cur_unit.on_selected()
	camera.set_target_gradually(_cur_unit)

func let_actor_move(actor: ActorController) -> void:
	actor.base3d.move_by_current_path()
	camera.follow_target_moving(actor.base3d)

# 只调用一次，除非手动 request_ready
# 所有子节点都已经添加到场景树后，才会调用
func _ready() -> void:
	if my_system == null:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		my_system = Game.g_combat
		my_system.init_with_scene_node(self)
	my_system.on_battle_start()

# 每次切到战斗场景都会调用
# 此时子节点还未添加
func _enter_tree() -> void:
	if my_system == null:
		return
	# Game.g_event.register_event(destination, on_event)
	my_system.on_battle_start()

# 战斗架构相关
func get_architecture():
	if my_system:
		return my_system.get_architecture()
func get_system(v):
	if my_system:
		return my_system.get_architecture().get_system(v)
func get_model(v):
	if my_system:
		return my_system.get_architecture().get_model(v)

func _configure_board_plane() -> void:
	var plane := board_plane.mesh
	if plane is PlaneMesh:
		plane.size = Vector2(map_cols * cell_world_size.x, map_rows * cell_world_size.y)
		board_plane.position = Vector3(plane.size.x * 0.5, 0.0, plane.size.y * 0.5)
		board_plane.mesh = plane

func _configure_subviewport() -> void:
	subvp.size = Vector2i(map_cols * cell_pixel_size.x, map_rows * cell_pixel_size.y)
	subvp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

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
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
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
				draw_debug_ray(from, hit)
				# 将世界坐标映射到格子坐标
				# print("Clicked pos: ", hit.x, ", ",  hit.z)
			var cell = ground_layer.local_to_map(Vector2(hit.x * cell_pixel_size.x, hit.z * cell_pixel_size.y))
			_on_cell_clicked(cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if my_system.get_battle_state() == BattleSystem.BattleState.ChoseActionTarget:
				Game.g_event.send_event("event_chose_target", false) # 点击右键取消所选动作

func _on_cell_clicked(cell: Vector2i) -> void:
	var battle_state = my_system.get_battle_state()
	if battle_state == BattleSystem.BattleState.ChoseActionTarget:
		Game.g_event.send_event("event_chose_target", cell)
		return
	if _cur_unit.is_target_cell(cell) and _cur_unit.get_cur_path().size() > 1:
		my_system.on_chose_action(ActionMove.new(_cur_unit.get_cur_path()))
		return
	if battle_state != BattleSystem.BattleState.ActorIdle:
		return
	var can_go := _cur_unit.set_target_cell(cell)
	if can_go:
		ground_layer.highlight_cell(cell, &"reachable")
	else:
		if ground_layer.path_cells.size() > 0:
			ground_layer.clear_path()
		var a = my_system.get_actor_on_cell(cell)
		if a:
			_on_actor_clicked(a, cell)
		else:
			ground_layer.highlight_cell(cell, &"unreachable")

func _on_actor_clicked(a: ActorController, cell: Vector2i) -> void:
	if a != _cur_unit.actor:
		if a.team_id == _cur_unit.actor.team_id:
			ground_layer.highlight_cell(cell, &"select_teammember")
			Game.g_event.send_event("event_chose_target", [a, ActionBase.TargetUnitType.SameTeam])
		else:
			ground_layer.highlight_cell(cell, &"select_other_team_actor")
			Game.g_event.send_event("event_chose_target", [a, ActionBase.TargetUnitType.OtherTeam])
	else:
		Game.g_event.send_event("event_chose_target", [a, ActionBase.TargetUnitType.Self])

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
	im.surface_add_vertex(from + dir)
	im.surface_end()
	line.mesh = im

	add_child(line)

	# 延迟清理
	await get_tree().create_timer(2.0).timeout
	line.queue_free()
