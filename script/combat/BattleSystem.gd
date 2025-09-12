class_name BattleSystem extends AbstractSystem

enum BattleState {
	Uninit, Init, Prepare, Wait, ActorIdle, ChoseActionTarget, ActorDoAction, AtEnd
}

var scene : BattleScene = null
var _cur_battle_name := ""
var _cur_state       := BattleState.Uninit

var _turn_controller : TurnController
var _buff_system : BuffSystem

var _units    : Array[UnitBase3D]
var _actors   : Array[ActorController]
var _cell_map : Dictionary[Vector2i, ActorController]

signal action_chosed
signal target_chosed

#region 流程控制

func get_battle_state() -> BattleState:
	return _cur_state

# 回合开始
func turn_started(actor: ActorController) -> void:
	_turn_controller.do_turn(actor)

# 回合结束
func turn_ended(_actor: ActorController) -> void:
	_cur_state = BattleState.Wait

# 更换当前角色
func change_cur_actor_to(actor: ActorController) -> void:
	if _cur_state == BattleState.ActorIdle or _cur_state == BattleState.Wait:
		if _turn_controller.change_cur_actor_to(actor):
			scene.select_current_actor(actor)
			_cur_state = BattleState.ActorIdle

# 开始选择动作
func begin_to_chose_action_for(actor: ActorController) -> void:
	scene.select_current_actor(actor)
	_cur_state = BattleState.ActorIdle

# 选择动作目标
func chose_action_target(actor: ActorController, action: ActionBase) -> bool:
	_cur_state = BattleState.ChoseActionTarget
	var target_data = null
	while true:
		target_data = await target_chosed
		if target_data == null:
			print("取消动作")
			break
		elif target_data is Array:
			if action.chose_target(target_data, actor):
				return true
	return false

# 开始动作
func let_actor_do_action(actor, action) -> void:
	actor.action = action
	if actor.action != null: # 持续性动作
		_cur_state = BattleState.ActorDoAction
		await actor.end_doing_action
		print("BattleSystem 收到信号 end_doing_action")

#endregion

#region 角色控制

func get_actors() -> Array[ActorController]:
	return _actors

func get_actors_in_team(id: Game.TeamID) -> Array[ActorController]:
	var actors = []
	for actor in _actors:
		if actor.team_id == id:
			actors.append(actor)
	return actors

func get_actors_not_in_team(id: Game.TeamID) -> Array[ActorController]:
	var actors = []
	for actor in _actors:
		if actor.team_id != id:
			actors.append(actor)
	return actors

func let_actor_move(a: ActorController) -> void:
	scene.let_actor_move(a)
	_cell_map.erase(a.base3d.get_cur_cell())
	_cell_map[a.base3d.get_cur_path().back()] = a

func get_actor_on_cell(c: Vector2i):
	if _cell_map.has(c):
		return _cell_map[c]
	else:
		return null

#endregion

func _init() -> void:
	_buff_system = BuffSystem.new()

#region 战斗架构

# 注册到架构时调用
func on_init():
	register_event("event_chose_action", on_chose_action)
	register_event("event_chose_target", on_chose_target)

func on_chose_action(action: ActionBase):
	print("选择动作：", action.get_action_name())
	action_chosed.emit(action)

func on_chose_target(target, target_type = -1):
	if _cur_state == BattleState.ChoseActionTarget:
		if target is Vector2i or target is ActorController:
			target_chosed.emit(target, target_type)
		elif target == false:
			target_chosed.emit()

func on_actor_hp_changed(actor, new_hp):
	print("BattleSystem 收到信号：", actor.my_name, " hp=", new_hp)
func on_actor_mp_changed(actor, new_mp):
	print("BattleSystem 收到信号：mp=", actor.my_name, " mp=", new_mp)

#endregion

#region 装载相关

# 开始战斗时，由 SceneManager 调用
func init_with_battle_name(battle_name: StringName) -> void:
	if _cur_battle_name != battle_name:
		_cur_state = BattleState.Init
		_units.clear()
		_actors.clear()
		_cell_map.clear()
		_cur_battle_name = battle_name

# 节点首次加载到场景树完毕时，由 BattleScene 调用
func init_with_scene_node(node: BattleScene) -> void:
	if scene != null:
		return
	scene = node
	_turn_controller = scene.turn_controller
	_turn_controller.set_timeline(scene.timeline)
	if get_architecture() == null:
		set_architecture(CombatArchitecture.new())
		print("战斗架构 CombatArchitecture 创建完毕")

func on_battle_start() -> void:
	print("战斗场景已添加，开始加载地图：", _cur_battle_name)
	if _cur_battle_name.is_empty():
		push_error("on_battle_start but battle_name is empty")
		return
	if scene == null:
		push_error("on_battle_start but battle scene is null")
		return
	var ok = await scene.load_battle_map(_cur_battle_name)
	if ok:
		create_initial_units_on_battle_map()
		scene.timeline.start()
		_cur_state = BattleState.Wait
	else:
		print("加载地图失败：", _cur_battle_name)
		_cur_battle_name = ""

func create_initial_units_on_battle_map() -> void:
	print("开始生成战斗单位...")
	# 根据 TileMap 上设置的标记，生成初始单位
	var actor_manager = Game.g_actors
	var map = scene.flag_layer as FlagLayer
	var flag_units = map.get_flag_units()
	for unit_name in flag_units.keys():
		if actor_manager.actors.exists(unit_name) == false:
			push_warning("地图 ", _cur_battle_name, " 中的 unit: ", unit_name, " 是不存在的角色！")
			continue
		var actor : ActorController = actor_manager.get_actor_by_name(unit_name)
		var template : PackedScene = actor_manager.actors.get_scene(unit_name)
		var cells = flag_units[unit_name] as Array
		if actor and cells.size() > 1:
			push_error("地图 ", _cur_battle_name, " 中的 unit: ", unit_name, " 不能放置超过1个！自动删除到只剩1个")
			for i in range(cells.size() - 1, 0, -1):
				cells.remove_at(i)
		for cell in cells:
			var look := true if _units.is_empty() else false
			print("开始添加单位 ", _units.size() + 1 ,"：", unit_name, "，坐标(", cell.x, ",", cell.y, ") 队伍 ", map.get_team_by_cell(cell))
			var unit := scene.add_unit_to(template, cell, look)
			if not actor_manager.get_actor_by_name(unit_name):
				actor = unit.get_child(1) # 获取子节点 ActorDefault
			else:
				unit.add_child(actor)
			unit.actor = actor
			unit.anim = unit.get_child(0)
			actor.base3d = unit
			actor.anim_player = unit.anim
			actor.team_id = map.get_team_by_cell(cell)
			_units.push_back(unit)
			_actors.push_back(actor)
			_cell_map[cell] = actor
	print("战斗单位已加载完毕")
	

func on_battle_map_unload() -> void:
	# 释放 _actors 中那些只在本场战斗中使用的角色
	var unit_cnt = _units.size()
	for i in range(unit_cnt):
		if Game.g_actors.is_character(_units[i]) == false:
			_actors[i].queue_free()
	init_with_battle_name("")

#endregion
