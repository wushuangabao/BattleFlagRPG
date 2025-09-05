class_name BattleController

var scene         : BattleScene   = null
var actor_manager : ActorManager

var _cur_battle_name := ""

var _units    : Array[UnitBase3D]
var _actors   : Array[ActorController]

func set_battle_name(battle_name: StringName) -> void:
	if _cur_battle_name != battle_name:
		_units.clear()
		_actors.clear()
		_cur_battle_name = battle_name

func set_scene_node(node: BattleScene) -> void:
	if scene != null:
		return
	scene = node
	actor_manager = Game.g_actors
	
func on_battle_start() -> void:
	if _cur_battle_name.is_empty():
		push_error("on_battle_start but battle_name is empty")
		return
	if scene == null:
		push_error("on_battle_start but battle scene is null")
		return
	if Game.Debug == 1:
		print("on_battle_start: ", _cur_battle_name)
	if scene.load_battle_map(_cur_battle_name):
		if Game.Debug == 1:
			print("on_battle_start: scene.load_battle_map ok")
	else:
		_cur_battle_name = ""

func on_battle_map_loaded() -> void:
	# 根据 TileMap 上设置的标记，生成初始单位
	var map = scene.flag_layer as FlagLayer
	var flag_units = map.get_flag_units()
	for unit_name in flag_units.keys():
		if actor_manager.actors.exists(unit_name) == false:
			push_warning("地图 ", _cur_battle_name, " 中的 unit: ", unit_name, " 是不存在的角色！")
			continue
		var actor : ActorController = actor_manager.get_actor_by_name(unit_name)
		var template : PackedScene = actor_manager.actors.get_scene(unit_name)
		var cells = flag_units[unit_name] as Array
		if cells.size() > 1 and actor_manager.is_character(template):
			push_error("地图 ", _cur_battle_name, " 中的 unit: ", unit_name, " 不能放置超过1个！自动删除到只剩1个")
			for i in range(cells.size() - 1, 0, -1):
				cells.remove_at(i)
		for cell in cells:
			var look := true if _units.is_empty() else false
			if Game.Debug == 1:
				print("add actor ", unit_name)
			var unit := scene.add_unit_to(template, cell, look)
			if not actor:
				actor = unit.get_child(1) # 获取子节点 ActorDefault
			_units.push_back(unit)
			_actors.push_back(actor)
	if Game.Debug == 1:
		print("所有角色已经加载完毕")
		_actors[0].add_HP(-1)

func on_battle_map_unload() -> void:
	# 释放 _actors 中那些只在本场战斗中使用的角色
	var unit_cnt = _units.size()
	for i in range(unit_cnt):
		if actor_manager.is_character(_units[i]) == false:
			_actors[i].queue_free()
	_units.clear()
	_actors.clear()
	_cur_battle_name = ""
