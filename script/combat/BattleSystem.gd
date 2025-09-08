class_name BattleSystem extends AbstractSystem

enum BattleState {
	Init, Prepare, Wait, ChangeCurActor, ActorIdle, ChoseActionTarget, ActorDoAction, AtEnd
}

var scene : BattleScene   = null
var _cur_battle_name := ""
var _cur_state       := BattleState.Init

var _turn_controller : TurnController
var _buff_system : BuffSystem

var _units    : Array[UnitBase3D]
var _actors   : Array[ActorController]
var _cell_map : Dictionary[Vector2i, ActorController]

func get_battle_state() -> BattleState:
	return _cur_state

func turn_started(actor: ActorController) -> void:
	_cur_state = BattleState.ActorIdle
	scene.select_current_actor(actor)

func turn_ended(_actor: ActorController) -> void:
	_cur_state = BattleState.Wait

func begin_to_chose_action_for(actor: ActorController) -> void:
	scene.select_preview_actor(actor)
	_cur_state = BattleState.ActorIdle

func begin_to_do_action(actor, _action) -> void:
	scene.release_preview_actor(actor)
	_cur_state = BattleState.ActorDoAction

func end_doing_action(_actor, _action) -> void:
	_cur_state = BattleState.ActorIdle

func get_battle_state_string() -> String:
	match _cur_state:
		BattleState.Init:
			return "Init"
		BattleState.Prepare:
			return "Prepare"
		BattleState.Wait:
			return "Wait"
		BattleState.ChangeCurActor:
			return "ChangeCurActor"
		BattleState.ActorIdle:
			return "ActorIdle" # can chose action
		BattleState.ChoseActionTarget:
			return "ChoseActionTarget"
		BattleState.ActorDoAction:
			return "ActorDoAction"
		BattleState.AtEnd:
			return "AtEnd"
	push_error("get_battle_state_string: Invalid state!")
	return "Unknown"

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

func _init() -> void:
	_buff_system = BuffSystem.new()

# 注册到架构时调用
func on_init():
	register_event("actor_hp_changed", on_actor_hp_changed)
	register_event("actor_mp_changed", on_actor_mp_changed)

func on_actor_hp_changed(actor, new_hp):
	print("BattleSystem 收到信号：", actor.my_name, " hp=", new_hp)
func on_actor_mp_changed(actor, new_mp):
	print("BattleSystem 收到信号：mp=", actor.my_name, " mp=", new_mp)

func init_with_battle_name(battle_name: StringName) -> void:
	if _cur_battle_name != battle_name:
		_cur_state = BattleState.Init
		_units.clear()
		_actors.clear()
		_cell_map.clear()
		_cur_battle_name = battle_name

func init_with_scene_node(node: BattleScene) -> void:
	if scene != null:
		return
	scene = node
	_turn_controller = scene.turn_controller
	_turn_controller.set_timeline(scene.timeline)
	scene.timeline.actor_ready.connect(_turn_controller.do_turn)

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
