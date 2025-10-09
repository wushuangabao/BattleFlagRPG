extends Node

const SAVE_VERSION := 1

const ACTION_SAVE_QUICK := "save_quick"
const ACTION_LOAD_QUICK := "load_quick"

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
	if event.is_action_pressed(ACTION_SAVE_QUICK):
		save_slot()
	elif event.is_action_pressed(ACTION_LOAD_QUICK):
		load_slot()

func get_save_path(slot: int = 1) -> String:
	return "user://save_%d.json" % slot

func save_slot(slot: int = 1) -> bool:
	if Game.g_scenes == null:
		push_warning("Save failed: SceneManager not ready")
		return false
	var scene_info: Dictionary = {}
	scene_info["current_scene_path"] = Game.g_scenes._current_scene.resource_path if Game.g_scenes._current_scene else ""
	var in_viewer := Game.g_scenes._current_scene == Game.g_scenes.sceneviewer_scene
	scene_info["in_viewer"] = in_viewer
	scene_info["stack_paths"] = []
	if in_viewer and Game.g_scenes._scene_navigator and Game.g_scenes._scene_navigator.stack:
		for sd in Game.g_scenes._scene_navigator.stack:
			if sd and sd is SceneData:
				(scene_info["stack_paths"] as Array).append(sd.resource_path)

	var story_info: Dictionary = {}
	if Game.g_runner:
		story_info = Game.g_runner.save_state()

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

	var path := get_save_path(slot)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Save failed: cannot open file " + path)
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

func load_slot(slot: int = 1) -> bool:
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		push_warning("Load failed: file not found " + path)
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Load failed: cannot open file " + path)
		return false
	var txt := f.get_as_text()
	f.close()
	var parse = JSON.parse_string(txt)
	if parse == null or not (parse is Dictionary):
		push_warning("Load failed: parse json error")
		return false
	var data: Dictionary = parse

	# 恢复角色
	if Game.g_actors and ActorManager._actors_nameMap:
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

	# 恢复场景
	if Game.g_scenes:
		var scene_info: Dictionary = data.get("scene", {})
		var in_viewer: bool = scene_info.get("in_viewer", false)
		if in_viewer:
			var stack_paths: Array = scene_info.get("stack_paths", [])
			var stack_size = stack_paths.size()
			if stack_size > 0:
				Game.g_scenes.clear_scene()
				for i in range(0, stack_size):
					var sd: SceneData = load(stack_paths[i])
					if sd:
						if i + 1 == stack_size:
							Game.g_scenes.push_scene(sd)
						else:
							Game.g_scenes.push_scene_data(sd)
		else:
			var scene_path: String = scene_info.get("current_scene_path", "")
			if scene_path != "":
				var ps: PackedScene = load(scene_path)
				if ps:
					await Game.g_scenes.goto_scene(ps)

	# 恢复剧情
	if Game.g_runner:
		Game.g_runner.restore_state(data.get("story", {}))

	return true
