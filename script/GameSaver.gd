extends Node

const SAVE_VERSION := 1

const ACTION_SAVE_QUICK := "save_quick"
const ACTION_LOAD_QUICK := "load_quick"

# 存档/读档过程防护标志：进行中时禁止再次触发
var _is_processing: bool = false

func _ready() -> void:
	_ensure_actions()

func _ensure_actions() -> void:
	if not InputMap.has_action(ACTION_SAVE_QUICK):
		InputMap.add_action(ACTION_SAVE_QUICK)
		var ev := InputEventKey.new()
		ev.keycode = OS.find_keycode_from_string("F4")
		InputMap.action_add_event(ACTION_SAVE_QUICK, ev)
	
	if not InputMap.has_action(ACTION_LOAD_QUICK):
		InputMap.add_action(ACTION_LOAD_QUICK)
		var ev2 := InputEventKey.new()
		ev2.keycode = OS.find_keycode_from_string("F5")
		InputMap.action_add_event(ACTION_LOAD_QUICK, ev2)

func _unhandled_input(event: InputEvent) -> void:
	if _is_processing:
		return
	if Game.g_scenes == null:
		push_warning("Save/Load failed: SceneManager not ready")
		return
	if Game.g_scenes._current_scene == Game.g_scenes.main_scene:
		return
	if event.is_action_pressed(ACTION_SAVE_QUICK):
		save_game()
	elif event.is_action_pressed(ACTION_LOAD_QUICK):
		load_game()

func get_save_path(slot: int) -> String:
	return Game.SAVE_FOLDER + str(slot) + ".save"

func save_game(slot: int = 0) -> bool:
	if _is_processing:
		push_warning("Save ignored: operation in progress")
		return false
	
	if Game.g_scenes == null:
		push_warning("Save failed: SceneManager not ready")
		return false
	
	_is_processing = true

	var path := get_save_path(slot)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Save failed: cannot open file " + path)
		_is_processing = false
		return false
	
	Dialogic.Save.save(str(slot), false, Dialogic.Save.ThumbnailMode.NONE)
	
	var scene_info: Dictionary = {}
	var in_viewer := Game.g_scenes._current_scene == Game.g_scenes.sceneviewer_scene
	scene_info["current_scene_path"] = Game.g_scenes._current_scene.resource_path if Game.g_scenes._current_scene else ""
	scene_info["in_viewer"] = in_viewer
	scene_info["stack_paths"] = []
	if in_viewer and Game.g_scenes._scene_navigator and Game.g_scenes._scene_navigator.stack:
		for sd in Game.g_scenes._scene_navigator.stack:
			if sd and sd is SceneData:
				(scene_info["stack_paths"] as Array).append(sd.resource_path)

	var story_info: Dictionary = {}
	if Game.g_runner:
		story_info = Game.g_runner.save_story_state()
		if Game.g_runner.is_in_battle:
			_save_battle_info(scene_info) # 记录战斗前的原场景及其场景栈

	var actors_info: Array = []
	if Game.g_actors and ActorManager._actors_nameMap:
		for _name in ActorManager._actors_nameMap.keys():
			var actor: ActorController = ActorManager._actors_nameMap[_name]
			if not actor or not actor.my_stat:
				continue
			var st: UnitStat = actor.my_stat
			actors_info.append({
				"name": str(_name),
				"lv": st.LV.value if st.LV else 1,
				"hp": st.HP.value if st.HP else 0,
				"mp": st.MP.value if st.MP else 0,
			})

	var data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_dict_from_system(),
		"scene": scene_info,
		"story": story_info,
		"actors": actors_info,
	}

	f.store_string(JSON.stringify(data))
	f.close()

	_is_processing = false
	return true

func _save_battle_info(scene_info: Dictionary) -> void:
	scene_info["origin_scene_path"] = ""
	scene_info["origin_stack_paths"] = []
	if Game.g_scenes.origin_path and Game.g_scenes.origin_path != "":
		scene_info["origin_scene_path"] = Game.g_scenes.origin_path
		# 若原场景是 SceneViewer，则记录其栈
		if Game.g_scenes.origin_path == Game.g_scenes.sceneviewer_scene.resource_path:
			var origin_stack: Array = []
			if Game.g_scenes._scene_navigator and Game.g_scenes._scene_navigator.stack:
				for sd2 in Game.g_scenes._scene_navigator.stack:
					if sd2 and sd2 is SceneData:
						origin_stack.append(sd2.resource_path)
			scene_info["origin_stack_paths"] = origin_stack

func load_game(slot: int = 0) -> bool:
	if _is_processing:
		push_warning("Load ignored: operation in progress")
		return false
	
	if Game.g_actors == null or Game.g_scenes == null or Game.g_runner == null:
		push_warning("Load failed: SceneManager or ActorManager or StoryRunner not ready")
		return false

	_is_processing = true

	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		push_warning("Load failed: file not found " + path)
		_is_processing = false
		return false

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Load failed: cannot open file " + path)
		_is_processing = false
		return false
	
	var txt := f.get_as_text()
	f.close()
	var parse = JSON.parse_string(txt)
	if parse == null or not (parse is Dictionary):
		push_warning("Load failed: parse json error")
		_is_processing = false
		return false
	
	Game.g_runner.active_session_id = "" # 让StoryRunner不再运行
	Dialogic.end_timeline()
	var data: Dictionary = parse

	print("开始恢复角色...")
	_load_actors_info(data)		

	print("开始恢复剧情...")
	var cur_active_session_id := Game.g_runner.restore_story_state(data.get("story", {}))

	# 如果当前剧情节点为战斗节点，则记录需要启动的战斗地图
	var battle_map_to_start: PackedScene = null
	var sid := Game.g_runner.active_session_id
	if sid != "":
		var cur_node := Game.g_runner.graph_manager.get_current(sid)
		if cur_node and (cur_node is BattleNode):
			battle_map_to_start = (cur_node as BattleNode).battle
			Game.g_runner.is_in_battle = true
		else:
			Game.g_runner.is_in_battle = false

	print("开始恢复场景...")
	await _load_scene_info(data, battle_map_to_start)

	print("开始恢复对话...")
	Dialogic.Save.load(str(slot))

	await get_tree().create_timer(0.6).timeout
	Game.g_runner.active_session_id = cur_active_session_id
	
	print("读档成功 - ", str(slot))
	_is_processing = false
	return true

func _load_scene_info(data: Dictionary, battle_map_to_start: PackedScene) -> void:
	var scene_info: Dictionary = data.get("scene", {})
	var in_viewer: bool = scene_info.get("in_viewer", false)

	# 若当前剧情为战斗节点：进入战斗并恢复原场景（战斗前场景）
	if battle_map_to_start != null:
		var origin_scene_path: String = scene_info.get("origin_scene_path", "")
		var origin_stack_paths: Array = scene_info.get("origin_stack_paths", [])
		if origin_scene_path != "":
			var origin_ps: PackedScene = load(origin_scene_path)
			if origin_ps:
				# 启动新战斗（等待场景切换完成）
				await Game.g_scenes.start_battle(battle_map_to_start, origin_ps)
				# 恢复原场景
				if Game.g_scenes.sceneviewer_scene and origin_ps == Game.g_scenes.sceneviewer_scene:
					Game.g_scenes.clear_scene()
					var osize := origin_stack_paths.size()
					if osize > 0:
						for i in range(0, osize):
							var sd_o: SceneData = load(origin_stack_paths[i])
							if sd_o:
								Game.g_scenes.push_scene_data(sd_o)
	elif in_viewer:
		var stack_paths: Array = scene_info.get("stack_paths", [])
		var stack_size = stack_paths.size()
		if stack_size > 0:
			Game.g_scenes.clear_scene()
			for i in range(0, stack_size):
				var sd: SceneData = load(stack_paths[i])
				if sd:
					if i + 1 == stack_size:
						await Game.g_scenes.push_scene(sd)
					else:
						Game.g_scenes.push_scene_data(sd)
	else:
		var scene_path: String = scene_info.get("current_scene_path", "")
		if scene_path != "":
			var ps: PackedScene = load(scene_path)
			if ps:
				await Game.g_scenes.goto_scene(ps)

func _load_actors_info(data: Dictionary) -> void:
	var actors_info: Array = data.get("actors", [])
	for a in actors_info:
		var _name := a.get("name", "") as StringName
		if _name == "":
			continue
		var actor: ActorController = Game.g_actors.get_actor_by_name(_name)
		if not actor or not actor.my_stat:
			continue
		var st: UnitStat = actor.my_stat
		# 先恢复等级以便重新计算最大值
		if st.LV:
			st.LV.set_value(int(a.get("lv", st.LV.value)))
			st.update_all_by_base_attr()
		# 再恢复当前 HP/MP（受最大值限制）
		if st.HP:
			st.HP.set_value(int(a.get("hp", st.HP.value)))
		if st.MP:
			st.MP.set_value(int(a.get("mp", st.MP.value)))
