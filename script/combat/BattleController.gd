class_name BattleController

var scene : BattleScene
var units : Array[UnitBase3D]

var cur_battle_name := ""

func set_scene_node(node: BattleScene) -> void:
	scene = node
	
func on_battle_start() -> void:
	if cur_battle_name.is_empty():
		push_error("on_battle_start but battle_name is empty")
		return
	if scene == null:
		push_error("on_battle_start but battle scene is null")
		return
	if Game.Debug == 1:
		print("on_battle_start: ", cur_battle_name)
	var ok = scene.load_battle_map(cur_battle_name)
	if ok:
		if Game.Debug == 1:
			print("on_battle_start: scene.load_battle_map ok")
	else:
		cur_battle_name = ""

func on_battle_map_loaded() -> void:
	# 根据 TileMap 上设置的标记，生成初始单位
	var map = scene.flag_layer as FlagLayer
	var flag_units = map.get_flag_units()
	for unit_name in flag_units.keys():
		var actor = Game.g_actors.get_actor_by_name(unit_name)
		var cells = flag_units[unit_name]
		for cell in cells:
			var look := true if units.is_empty() else false
			var unit := scene.add_unit_to(actor, cell, look)
			units.append(unit)
