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
@onready var bottom_panel := $TurnController/Background/bottom_panel as BottomPanel

var _cur_unit : UnitBase3D = null
var _unit_list : Array[UnitBase3D]

var _cell_mouse_on  # 鼠标指向的单元格
var _target_units : Array[ActorController] # 动作选择 - 目标单位组

var my_system : BattleSystem = null
var ground_layer : GroundLayer
var flag_layer   : FlagLayer

# 地图行列数（用于计算SubViewport size与Plane尺寸）
var map_cols: int
var map_rows: int

var cell_pixel_size = Game.cell_pixel_size
var cell_world_size = Game.cell_world_size

#region 角色控制

func add_unit_to(unit_template: PackedScene, cell: Vector2i, islook:= false) -> UnitBase3D:
	if ground_layer == null:
		push_error("add unit to Nil ground!")
	var new_unit = unit_template.instantiate() as UnitBase3D
	new_unit.map = ground_layer
	new_unit.set_cur_cell(cell)
	if islook:
		_cur_unit = new_unit
		new_unit.initialized.connect(_on_cur_actor_initialized, CONNECT_ONE_SHOT)
	add_child(new_unit)
	_unit_list.append(new_unit)
	return new_unit

func _on_cur_actor_initialized(unit_node: UnitBase3D) -> void:
	if unit_node != _cur_unit:
		return
	bottom_panel.set_actor(unit_node.actor)
	camera.set_target_immediately(_cur_unit)

# 选择预览角色（相机聚焦、高亮轮廓）
func select_preview_actor(actor: ActorController) -> void:
	if actor:
		for a in my_system.get_actors():
			if a != actor:
				a.anim_player.highlight_off()
			else:
				a.anim_player.highlight_on()
		bottom_panel.set_actor(actor)
		camera.set_target_gradually(actor.base3d)

# 取消预览角色（可能会回到当前角色）
func release_preview_actor(actor: ActorController) -> void:
	if actor and actor is ActorController:
		if _cur_unit and Game.g_combat.get_battle_state() == BattleSystem.BattleState.ActorIdle:
			select_preview_actor(_cur_unit.actor)
			bottom_panel.set_actor(_cur_unit.actor)
			camera.set_target_gradually(_cur_unit)
		else:
			for a in my_system.get_actors():
				a.anim_player.highlight_off()

# 选取角色（准备做动作）
func select_current_actor(actor: ActorController) -> void:
	ground_layer.clear_on_change_cur_actor_to(actor)
	_cur_unit = actor.base3d
	_cur_unit.on_selected()
	select_preview_actor(actor)

func let_actor_move(actor: ActorController) -> void:
	actor.base3d.move_by_current_path()
	camera.follow_target_moving(actor.base3d)

#endregion

#region 战斗架构相关

func get_architecture():
	if my_system:
		return my_system.get_architecture()
func get_system(v):
	if my_system:
		return my_system.get_architecture().get_system(v)
func get_model(v):
	if my_system:
		return my_system.get_architecture().get_model(v)

#endregion

#region 加载战斗地图

# 只调用一次，除非手动 request_ready
# 所有子节点都已经添加到场景树后，才会调用
func _ready() -> void:
	if my_system == null:
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

func load_battle_map(map: PackedScene) -> bool:
	var new_node := await subvp.loadScene_battleMap(map)
	if new_node == null:
		return false
	ground_layer = new_node.ground
	flag_layer   = new_node.flag
	var dim = ground_layer.get_tilemap_dimensions()
	map_cols = dim.x
	map_rows = dim.y
	camera.set_boundary(dim, ground_layer.position.y)
	_configure_subviewport()
	_configure_board_plane()
	_hook_subviewport_texture_to_plane()
	subvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	print("战斗地图加载完毕 - ", subvp.get_cur_scene_path())
	return true

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

# 切换场景时释放资源
func release_on_change_scene():
	for u in _unit_list:
		u.queue_free()
	_unit_list.clear()
	subvp.release_battleMap()
	my_system.on_battle_map_unload()

#endregion

#region 输入捕获

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var battle_state = my_system.get_battle_state()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if battle_state == BattleSystem.BattleState.ChoseActionTarget:
				if _cell_mouse_on and ground_layer.chose_area_cells.has(_cell_mouse_on):
					for tar in _target_units:
						tar.anim_player.highlight_off()
					Game.g_event.send_event("event_chose_target", ground_layer.skill_area_cells) # 选择目标
					return
			_cell_mouse_on = _get_cell_mouse_on()
			if _cell_mouse_on:
				_on_cell_clicked(_cell_mouse_on)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if battle_state == BattleSystem.BattleState.ChoseActionTarget:
				Game.g_event.send_event("event_chose_target", false) # 点击右键取消所选动作

func _on_cell_clicked(cell: Vector2i) -> void:
	if _cur_unit.is_target_cell(cell) and _cur_unit.get_cur_path().size() > 1:
		my_system.on_chose_action(ActionMove.new(_cur_unit.get_cur_path()))
		return
	var battle_state = my_system.get_battle_state()
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
		else:
			ground_layer.highlight_cell(cell, &"select_other_team_actor")

func _process(_delta: float) -> void:
	var battle_state = my_system.get_battle_state()
	if battle_state == BattleSystem.BattleState.ChoseActionTarget and my_system.cur_action and my_system.cur_actor:
		_cell_mouse_on = _get_cell_mouse_on()
		if _cell_mouse_on:
			if ground_layer.chose_area_cells.has(_cell_mouse_on):
				ground_layer.highlight_cell(_cell_mouse_on, &"reachable")
				var skill_range = my_system.cur_action.get_area_skill_range(my_system.cur_actor, _cell_mouse_on)
				ground_layer.set_skill_area(skill_range)
				var targets := my_system.cur_action.get_targets_on_cells(skill_range, my_system.cur_actor)
				for tar in _target_units:
					if not targets.has(tar):
						tar.anim_player.highlight_off()
				for tar in targets:
					if not _target_units.has(tar):
						tar.anim_player.highlight_on(my_system.cur_action.target_highlight_type)
				_target_units = targets
			else:
				ground_layer.highlight_cell(_cell_mouse_on, &"unreachable")
				ground_layer.set_skill_area([])
				for tar in _target_units:
					tar.anim_player.highlight_off()
				_target_units.clear()
	else:
		_cell_mouse_on = null

func _get_cell_mouse_on():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var dir = camera.project_ray_normal(mouse_pos)
	# 与 y=0 平面求交
	if absf(dir.y) < 1e-6: # 射线几乎平行于地面
		return null
	var t = -from.y / dir.y
	if t <= 0.0: # 交点在摄像机背后
		return null
	var hit = from + dir * t
	# draw_debug_ray(from, hit)
	# 将世界坐标映射到格子坐标
	return ground_layer.local_to_map(Vector2(hit.x * cell_pixel_size.x, hit.z * cell_pixel_size.y))

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

#endregion
