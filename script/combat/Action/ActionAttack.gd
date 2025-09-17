class_name ActionAttack extends ActionBase

var _skill : Skill

func _init(skill: Skill) -> void:
	_skill = skill
	cost = skill.cost
	target_type = TargetType.Unit
	target_highlight_type = UnitAnimatedSprite3D.HighLightType.TargetRed

func get_action_name() -> StringName:
	return &"attack"

func get_area_chose_target(me: ActorController) -> Array[Vector2i]:
	var center := me.base3d._cell
	return GridHelper.get_skill_area_cells(_skill.area_chose, center, center, func(c):
		if Game.g_combat.scene.ground_layer.get_cell_source_id(c) == -1:
			return false	
		return true
	)

func get_area_skill_range(me: ActorController, tar: Vector2i) -> Array[Vector2i]:
	var org := me.base3d._cell
	return GridHelper.get_skill_area_cells(_skill.area_range, org, tar, func(c):
		if c == org:
			return false
		if Game.g_combat.scene.ground_layer.get_cell_source_id(c) == -1:
			return false
		return true
	)

func check_target_units(chosed_targets: Array[ActorController], me: ActorController) -> bool:
	var filtered_targets = _skill.filter_targets(chosed_targets, me)
	chosed_targets.clear()  # 清空原数组并添加过滤后的元素，这样可以保持原引用不变
	for tar in filtered_targets:
		chosed_targets.append(tar)
	if chosed_targets.size() == 0:
		return false
	return true

func start(actor: ActorController) -> void:
	print(actor.my_name, " 发动了攻击！消耗AP：", cost[&"AP"])
	actor.anim_player.play(&"attack")
	for tar in target:
		tar.animate_take_damage_after(0.5)
	_state = ActionState.Running

# 在角色_process中执行
func update(actor: ActorController, _delta: float) -> void:
	if not actor.anim_player.is_playing() and actor.anim_player.animation == &"attack":
		actor.anim_player.play(&"idle")
		_state = ActionState.Terminated
		for tar in target:
			var target_actor = tar as ActorController
			target_actor.anim_player.highlight_off()
			if target_actor.get_state() == ActorController.ActorState.Defend:
				target_actor.take_damage(20, actor)
				target_actor.anim_player.play(&"defend")
			else:
				target_actor.take_damage(80, actor)
				target_actor.anim_player.play(&"idle")
