class_name TurnController extends AbstractController

var timeline : TimelineController

var _actor
var _stop_requested := false

# 玩家队伍列表：任意一个队伍全部死亡时玩家失败
var player_teams: Array[Game.TeamID] = []
# 敌人队伍列表：所有队伍全部死亡时玩家胜利
var enemy_teams: Array[Game.TeamID] = []

func set_timeline(tl: TimelineController) -> void:
	timeline = tl

# 设置玩家队伍列表
func set_player_teams(teams: Array[Game.TeamID]) -> void:
	player_teams = teams

# 设置敌人队伍列表
func set_enemy_teams(teams: Array[Game.TeamID]) -> void:
	enemy_teams = teams

# 设置战斗队伍配置（玩家队伍和敌人队伍）
func set_battle_teams(player_team_list: Array[Game.TeamID], enemy_team_list: Array[Game.TeamID]) -> void:
	player_teams = player_team_list
	enemy_teams = enemy_team_list

func stop_turn_loop() -> void:
	_stop_requested = true
	print("[TurnController] 请求停止 do_turn 循环")

func do_turn(actor: ActorController) -> void:
	_stop_requested = false
	print("现在是 %s （%s，AP=%d）的回合..." % [actor.my_name, str(actor), actor.get_AP()])
	
	# 调试：打印准备队列中的角色名字和AP
	var _rq_msg := "ready_queue: "
	for a in timeline.ready_queue:
		_rq_msg += str(a.my_name) + "(%s,AP=%d) " % [str(a), a.get_AP()]
	print(_rq_msg)

	_actor = actor  # _actor 才是当前选择、执行动作的角色，actor 不是！因为在 while 循环中，可能重新赋值 _actor 为其他角色
	var battle = Game.g_combat
	while true:
		if _stop_requested:
			print("[TurnController] 停止标记命中，退出 do_turn 循环")
			break
		# 角色是否可行动
		if not _actor.is_alive() or not has_affordable_actions(_actor):
			if _try_next_actor_do_turn():
				continue
			else:
				break
		# 选择动作
		battle.begin_to_chose_action_for(_actor)
		var action: ActionBase = await Game.g_combat.action_chosed
		if _stop_requested:
			print("[TurnController] 在等待 action_chosed 后收到停止请求，退出")
			break
		if action == null:
			print("动作无效 - ", _actor.my_name)
			continue
		if not action.validate(_actor):
			print("动作未通过校验 - %s(%s) - %s" % [_actor.my_name, str(_actor), action.get_action_name()])
			continue
		# 选择动作完毕
		_actor.anim_player.highlight_off()
		if action.get_action_name() == &"skip_turn":
			print("执行动作 - 跳过回合")
			_actor.clear_AP()
			timeline.update_actor_btn_pos(_actor, timeline.ready_queue.size() > 0)
			if _try_next_actor_do_turn():
				continue
			else:
				break
		# 选择目标，或者取消动作
		if action.target_type != ActionBase.TargetType.None:
			var ok = await battle.chose_action_target(_actor, action)
			if _stop_requested:
				print("[TurnController] 在等待 chose_action_target 后收到停止请求，退出")
				break
			if not ok:
				continue
		# 动作消耗
		action.pay_costs(_actor)
		timeline.update_actor_btn_pos(_actor, true)
		# 执行动作
		await battle.let_actor_do_action(_actor, action)
		if _stop_requested:
			print("[TurnController] 在等待 let_actor_do_action 后收到停止请求，退出")
			break
	if _stop_requested:
		_actor = null
		return
	battle.turn_ended()
	var battle_result = _check_battle_end()
	var is_battle_end = battle_result[0]
	var player_victory = battle_result[1]
	
	if is_battle_end:
		battle.on_battle_end(player_victory)
		return
	timeline.resume_timeline()
	_actor = null

func _try_next_actor_do_turn() -> bool:
	while timeline.ready_queue.size() > 0:
		if change_cur_actor_to(timeline.ready_queue.pop_front()):
			return true
	return false

func change_cur_actor_to(actor: ActorController) -> bool:
	if not actor.is_alive():
		return false
	if actor.get_AP() < TimelineController.AP_THRESHOLD:
		return false
	if actor.get_state() == ActorController.ActorState.DoAction:
		return false
	timeline.set_actor_actived_on_timeline(actor)
	if _actor == null:
		do_turn(actor)
	else:
		print("已经切换到 %s （%s，AP=%d）的回合..." % [actor.my_name, str(actor), actor.get_AP()])
		_actor = actor
	Game.g_combat.scene.select_current_actor(actor)
	return true

func has_affordable_actions(actor: ActorController) -> bool:
	if actor.get_AP() > 0:
		return true
	else:
		return false

# 检查战斗结束条件：
# - 当指定的玩家队伍中任意一个队伍全部死亡时，玩家失败
# - 当指定的敌人队伍全部队伍中所有角色都死亡时，玩家胜利
# 返回值: [战斗是否结束, 玩家是否胜利] - [bool, bool]
func _check_battle_end() -> Array:
	var battle = Game.g_combat

	# 先执行 BattleMap 的自定义检查器
	if battle.scene.subvp.get_child_count() < 1:
		push_warning("BattleMap 未初始化")
		return [false, false]
	var map = battle.scene.subvp.get_child(0)
	if map and map is BattleMap:
		if map.win_checker:
			if map.win_checker.evaluate({}):
				return [true, true]
		if map.lose_checker:
			if map.lose_checker.evaluate({}):
				return [true, false]
	
	# 如果没有指定队伍，使用默认判断逻辑
	if player_teams.is_empty() and enemy_teams.is_empty():
		return [_check_battle_end_legacy(), false]  # 不返回胜负
	
	# 检查玩家队伍：任意一个队伍全部死亡则玩家失败
	for team_id in player_teams:
		var team_actors = battle.get_actors_in_team(team_id)
		# 如果队伍中没有角色，跳过检查
		if team_actors.is_empty():
			continue
			
		var has_alive_actor = false
		for actor in team_actors:
			if actor.is_alive():
				has_alive_actor = true
				break
		
		# 如果某个玩家队伍没有存活的角色，玩家失败
		if not has_alive_actor:
			print("玩家队伍 ", team_id, " 全部死亡，玩家失败")
			return [true, false]  # 战斗结束，玩家失败
	
	# 检查敌人队伍：所有队伍的所有角色都死亡则玩家胜利
	var all_enemies_dead = true
	for team_id in enemy_teams:
		var team_actors = battle.get_actors_in_team(team_id)
		# 如果队伍中没有角色，跳过检查
		if team_actors.is_empty():
			continue
			
		var has_alive_actor = false
		for actor in team_actors:
			if actor.is_alive():
				has_alive_actor = true
				break
		
		# 如果某个敌人队伍还有存活角色，则不是全部死亡
		if has_alive_actor:
			all_enemies_dead = false
			break
	
	# 如果所有敌人队伍都没有存活角色，玩家胜利
	if all_enemies_dead and not enemy_teams.is_empty():
		print("所有敌人队伍全部死亡，玩家胜利")
		return [true, true]  # 战斗结束，玩家胜利
	
	return [false, false]  # 战斗继续

# 检查战斗结束条件（传统模式）：
# 检查是否只剩一个队伍里有角色存活，如果是，说明战斗已经结束
# 返回值: bool - 战斗是否结束
func _check_battle_end_legacy() -> bool:
	var battle = Game.g_combat
	var alive_teams: Dictionary = {}  # 记录每个队伍的存活角色数量
	
	# 统计每个队伍的存活角色数量
	for actor in battle.get_actors():
		if actor.is_alive():
			var team_id = actor.team_id
			if alive_teams.has(team_id):
				alive_teams[team_id] += 1
			else:
				alive_teams[team_id] = 1
	
	# 如果只有一个队伍有存活角色，或者没有存活角色，战斗结束
	if alive_teams.size() <= 1:
		if alive_teams.size() == 1:
			var remaining_team = alive_teams.keys()[0]
			print("只剩队伍 ", remaining_team, " 有存活角色，战斗结束")
		else:
			print("没有存活角色，战斗结束")
		return true
	
	return false  # 还有多个队伍有存活角色，战斗继续
