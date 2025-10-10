class_name BattleSystem extends AbstractSystem

enum BattleState {
	Uninit, Init, Prepare, Wait, ActorIdle, ChoseActionTarget, ActorDoAction, AtEnd
}

var _cur_state := BattleState.Uninit

var scene : BattleScene = null
var _cur_battle_path  := ""
var _cur_battle_scene : PackedScene = null

var _turn_controller : TurnController
var _buff_system : BuffSystem

var _actors   : Array[ActorController]
var _cell_map : Dictionary[Vector2i, ActorController]

# 战斗回放相关 - 随机种子管理
var _battle_seed : int = 0
var _replay_data : Array[Dictionary] = []

# 正在选择动作目标 - 存储角色和动作
var cur_actor  : ActorController
var cur_action : ActionBase = null

signal action_chosed
signal target_chosed

#region 流程控制

func get_battle_state() -> BattleState:
	return _cur_state

# 回合开始
func turn_started(actor: ActorController) -> void:
	_turn_controller.do_turn(actor)

# 回合结束
func turn_ended() -> void:
	_cur_state = BattleState.Wait

# 更换当前角色
func change_cur_actor_to(actor: ActorController) -> void:
	if _cur_state == BattleState.ActorIdle or _cur_state == BattleState.Wait:
		if _turn_controller.change_cur_actor_to(actor):
			_cur_state = BattleState.ActorIdle

# 开始选择动作
func begin_to_chose_action_for(actor: ActorController) -> void:
	scene.select_current_actor(actor)
	_cur_state = BattleState.ActorIdle
	info("%s : 选择动作" % [actor.my_name])

# 选择动作目标
func chose_action_target(actor: ActorController, action: ActionBase) -> bool:
	_cur_state = BattleState.ChoseActionTarget
	cur_actor = actor
	cur_action = action
	info("%s : 选择 [%s] 目标" % [actor.my_name, action.get_action_name()])
	scene.ground_layer.set_chose_area(action.get_area_chose_target(actor))
	var target_cells = null
	var ret = false
	while true:
		target_cells = await target_chosed
		if target_cells == null:
			info("%s : 取消动作" % [actor.my_name])
			break
		elif target_cells is Array[Vector2i] and target_cells.size() > 0:
			if action.target_type != ActionBase.TargetType.None:
				if action.chose_target(target_cells, actor):
					ret = true
					break
				else:
					info("无效的选择目标！", 2.0)
			else:
				push_error("目标类型为None的动作竟然在选择动作目标？！")
				break
	cur_actor = null
	cur_action = null
	scene.ground_layer.set_skill_area([])
	scene.ground_layer.set_chose_area([])
	return ret

# 开始动作
func let_actor_do_action(actor: ActorController, action: ActionBase) -> void:
	actor.action = action
	if actor.action != null: # 持续性动作
		if actor.action is ActionDefend:
			return
		_cur_state = BattleState.ActorDoAction
		info("%s : 开始动作 - %s" % [actor.my_name, action.get_action_name()])
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
	if a.base3d.get_cur_path().size() <= 1:
		return
	scene.let_actor_move(a)
	_cell_map.erase(a.base3d.get_cur_cell())
	_cell_map[a.base3d.get_cur_path().back()] = a

func get_actor_on_cell(c: Vector2i):
	if _cell_map.has(c):
		return _cell_map[c]
	else:
		return null

#endregion

#region 战斗回放相关

## 设置战斗随机种子（用于回放）
func set_battle_seed(the_seed: int) -> void:
	_battle_seed = the_seed
	PseudoRandom.set_seed(the_seed)
	print("战斗随机种子已设置：", the_seed)

## 获取当前战斗种子
func get_battle_seed() -> int:
	return _battle_seed

## 重置随机状态到战斗开始
func reset_random_state() -> void:
	PseudoRandom.set_seed(_battle_seed)
	print("随机状态已重置到战斗开始")

## 记录战斗动作（用于回放）
func record_action(actor_name: StringName, action_name: StringName, targets: Array = []) -> void:
	var action_data = {
		"actor": actor_name,
		"action": action_name,
		"targets": targets,
		"random_state": PseudoRandom.get_seed()
	}
	_replay_data.append(action_data)

## 获取回放数据
func get_replay_data() -> Array[Dictionary]:
	return _replay_data.duplicate()

## 清空回放数据
func clear_replay_data() -> void:
	_replay_data.clear()

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

func on_chose_target(target):
	if _cur_state == BattleState.ChoseActionTarget:
		if target is Array[Vector2i]:
			target_chosed.emit(target)
		elif target == false:
			target_chosed.emit()

func on_actor_hp_changed(actor, new_hp, old_hp):
	print("BattleSystem 收到信号：", actor.my_name, " hp=", new_hp)
	# 头顶血条
	var bar_hp = actor.base3d.bar_hp
	bar_hp.max_value = actor.get_MaxHP()
	bar_hp.set_value_no_signal(old_hp)
	actor.base3d.animate_hp_bar(new_hp)
	# 行动条头像
	if _turn_controller.timeline.texture_map.has(actor):
		var p = (bar_hp.max_value - new_hp) / bar_hp.max_value
		_turn_controller.timeline.texture_map[actor].set_hp_progress(p)

func on_actor_mp_changed(actor, new_mp, old_mp):
	print("BattleSystem 收到信号：mp=", actor.my_name, " mp=", new_mp)
	# 头顶蓝条
	var bar_mp = actor.base3d.bar_mp
	bar_mp.max_value = actor.my_stat.MP.maximum
	bar_mp.set_value_no_signal(old_mp)
	actor.base3d.animate_mp_bar(new_mp)

#endregion

#region 装载相关

# 开始战斗时，由 SceneManager 调用
func init_with_battle_scene(battle_scene: PackedScene) -> void:
	_cur_state = BattleState.Init
	_actors.clear()
	_cell_map.clear()
	if battle_scene:
		_cur_battle_scene = battle_scene
		_cur_battle_path = battle_scene.get_path()
	if _cur_battle_path.is_empty() or _cur_battle_scene == null:
		push_error("init_with_battle_scene but battle_name is empty")
		return
	on_battle_start()

# 节点首次加载到场景树完毕时，由 BattleScene 调用
func init_with_scene_node(node: BattleScene) -> void:
	if scene != null:
		return
	scene = node
	_turn_controller = scene.turn_controller
	_turn_controller.set_timeline(scene.timeline)
	Game.g_runner.m_architecture.register_system(self)
	print("战斗系统已经初始化")

func on_battle_start() -> void:
	print("战斗场景已添加，开始加载地图：", _cur_battle_path)
	if scene == null:
		push_error("on_battle_start but battle scene is null")
		return
	
	scene.is_released_ok = false

	# 初始化战斗随机种子（如果没有设置，使用当前时间）
	if _battle_seed == 0:
		_battle_seed = Time.get_unix_time_from_system() as int
	set_battle_seed(_battle_seed)
	clear_replay_data()
	
	var ok = await scene.load_battle_map(_cur_battle_scene)
	if ok:
		await create_initial_units_on_battle_map()
		scene.timeline.start()
		_cur_state = BattleState.Wait
	else:
		print("加载地图失败：", _cur_battle_path)
		_cur_battle_path = ""
		_cur_battle_scene = null

func on_battle_end(player_victory: bool) -> void:
	send_event("battle_end", player_victory)

func create_initial_units_on_battle_map() -> void:
	print("开始生成战斗单位...")
	# 根据 TileMap 上设置的标记，生成初始单位
	var actor_manager = Game.g_actors
	var team_ids_not_player : Array[Game.TeamID] = []
	var map := scene.flag_layer
	var flag_units = map.get_flag_units()
	for unit_name in flag_units.keys():
		if actor_manager.actors.exists(unit_name) == false:
			push_warning("地图 ", _cur_battle_path, " 中的 unit: ", unit_name, " 是不存在的角色！")
			continue
		var actor : ActorController = actor_manager.get_actor_by_name(unit_name)
		var template : PackedScene = actor_manager.actors.get_scene(unit_name)
		var cells = flag_units[unit_name] as Array
		if actor and cells.size() > 1:
			push_error("地图 ", _cur_battle_path, " 中的 unit: ", unit_name, " 不能放置超过1个！自动删除到只剩1个")
			for i in range(cells.size() - 1, 0, -1):
				cells.remove_at(i)
		for cell in cells:
			var look := true if _actors.is_empty() else false
			if Game.Debug == 1:
				print("开始添加单位 ", _actors.size() + 1 ,"：", unit_name, "，坐标(", cell.x, ",", cell.y, ") 队伍 ", map.get_team_by_cell(cell))
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
			_actors.push_back(actor)
			_cell_map[cell] = actor
			if not map.is_player_team(actor.team_id):
				team_ids_not_player.append(actor.team_id)
	_turn_controller.set_battle_teams(map.get_player_team_id(), team_ids_not_player)
	for a in _actors:
		if a.AP == null:
			await a.base3d.initialized
	print("战斗单位已加载完毕")

func on_battle_map_unload() -> void:
	# 清理 timeline，停止回合循环
	if _turn_controller:
		_turn_controller.stop_turn_loop()
	_turn_controller.timeline.clear_on_change_scene()
	_turn_controller.set_battle_teams([], [])
	# 清理 actors 和相关数据
	_actors.clear()
	_cell_map.clear()
	# 重置战斗状态
	_cur_state = BattleState.Uninit
	cur_actor = null
	cur_action = null

#endregion

#region UI相关

func info(txt: String, play_seconds: float = -1.0) -> void:
	if play_seconds > 0.01:
		scene.bottom_panel.put_info_tmp(txt, play_seconds)
	else:
		scene.bottom_panel.put_info(txt)

#regionend
