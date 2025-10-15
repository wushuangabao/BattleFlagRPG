# 角色控制器
class_name ActorController extends AbstractController

var my_stat  : UnitStat         # 数据
var character: DialogicCharacter# Dialogic角色数据

var AP       : AttributeBase    # 行动点
var tmp_timeline_y : float      # 在 timeline 上头像的 y 坐标

var sect     : = Game.Sect.None   # 门派
var camp     : = Game.Camp.Player # 阵营
var team_id  : = Game.TeamID.Red  # 队伍

var tags     : Array[StringName]
var buffs    : Array[BuffBase]    # buff 列表
var actions  : Array[ActionBase]  # 待执行动作列表

@export var my_name  : StringName     # 角色名（唯一）
@export var base3d   : UnitBase3D     # 在场景中显示用
@export var skills   : Array[Skill]   # 技能列表
@export var anim_player: UnitAnimatedSprite3D # 动画节点的引用

enum ActorState {
	Idle, DoAction, Defend
}

enum FacingDirection {
	Right = 0,  # 右 (1, 0)
	Down = 1,   # 下 (0, 1)
	Left = 2,   # 左 (-1, 0)
	Up = 3      # 上 (0, -1)
}

var _state : ActorState = ActorState.Idle
var _action: ActionBase = null
var facing_direction : FacingDirection = FacingDirection.Right

func get_state() -> ActorState:
	return _state

# 根据移动方向更新面朝方向
func update_facing_direction(dir: Vector2i) -> void:
	if dir.x > 0:
		facing_direction = FacingDirection.Right
	elif dir.x < 0:
		facing_direction = FacingDirection.Left
	elif dir.y > 0:
		facing_direction = FacingDirection.Down
	elif dir.y < 0:
		facing_direction = FacingDirection.Up

# 获取面朝方向的Vector2i表示
func get_facing_vector() -> Vector2i:
	match facing_direction:
		FacingDirection.Right:
			return Vector2i(1, 0)
		FacingDirection.Down:
			return Vector2i(0, 1)
		FacingDirection.Left:
			return Vector2i(-1, 0)
		FacingDirection.Up:
			return Vector2i(0, -1)
		_:
			return Vector2i(1, 0)

func has_tag(_tags: Array[StringName]) -> bool:
	for t in _tags:
		if tags.has(t):
			return true
	return false

# signal begin_to_do_action
signal end_doing_action

var action:
	get:
		return _action
	set(new_action):
		# 取消防御
		if _action and _action is ActionDefend and not new_action is ActionDefend:
			_action.cancel()
			_action = null
		# 执行新动作（execute）
		if _action == null:
			if new_action is ActionDefend:
				_state = ActorState.Defend
			else:
				_state = ActorState.DoAction
			if new_action.execute(self) == ActionBase.ActionState.Running:
				_action = new_action
				# begin_to_do_action.emit(new_action)
			else:
				_state = ActorState.Idle # 动作执行一瞬间就结束了，不用发信号

 # 初始化角色数值表
func init_actor_data(actor_name) -> void:
	my_name = actor_name
	my_stat = UnitStat.new(self)
	character = DialogicResourceUtil.get_character_resource(actor_name)
	if character == null:
		push_warning("角色[%s]未配置 Dialogic 角色信息" % actor_name)
	else:
		print("角色[%s]基础属性数据初始化完毕" % actor_name)

func _enter_tree() -> void:
	_state = ActorState.Idle
	_action = null
	tags.clear()
	buffs.clear()
	actions.clear()
	tmp_timeline_y = 0.0
	facing_direction = FacingDirection.Right # 默认向右
	AP = AttributeBase.new(self, 0, TimelineController.AP_MAX)
	if my_stat == null:
		my_stat = UnitStat.new(self)
	Game.g_combat.get_architecture().register_actor(self)

func _exit_tree() -> void:
	# print("角色已从树中移除 ", my_name)
	Game.g_combat.get_architecture().unregister_actor(self)

func _process(delta: float) -> void:
	if _state != ActorState.Idle:
		if _action == null:
			push_error("角色状态不是Idle 但_action为空！")
			_state = ActorState.Idle
			return
		_action.update(self, delta)
		if _action.get_state() == ActionBase.ActionState.Terminated:
			_state = ActorState.Idle
			print("end_doing_action emit")
			end_doing_action.emit(_action)
			_action = null

func add_HP(v: int) -> void:
	my_stat.HP.set_value(my_stat.HP.value + v)

func get_HP() -> int:
	return my_stat.HP.value

func get_MaxHP() -> int:
	return my_stat.HP.maximum

func add_MP(v: int) -> void:
	my_stat.MP.set_value(my_stat.MP.value + v)

func get_MP() -> int:
	return my_stat.MP.value

func get_MaxMP() -> int:
	return my_stat.MP.maximum

func add_AP(v: int) -> void:
	AP.set_value(AP.value + v)

func pay_AP(v: int) -> void:
	AP.set_value(AP.value - v)

func clear_AP() -> void:
	AP.set_value(0)

func get_AP() -> int:
	return AP.value

func get_ap_gain_per_sec() -> float:
	return Game.BASE_SPD * (1 + my_stat.SPD.value)

func add_buff(buf: BuffBase) -> bool:
	buffs.push_back(buf)
	return true

func add_action(act: ActionBase) -> void:
	actions.push_back(act)

#region 技能相关

func learn_skill(skill: Skill) -> void:
	if skill == null:
		return
	if skills == null:
		skills = []
	if not skills.has(skill):
		skills.append(skill)

func forget_skill(skill: Skill) -> void:
	if skills == null or skill == null:
		return
	skills.erase(skill)

func get_skill_by_name(n: String) -> Skill:
	if skills == null:
		return null
	for s in skills:
		if s and s.name == n:
			return s
	return null

func get_skill_by_index(i: int) -> Skill:
	if skills == null:
		return null
	if i >= 0 and i < skills.size():
		return skills[i]
	return null

func add_skill_by_path(res_path: String) -> bool:
	if res_path == "":
		return false
	var res = load(res_path)
	if res and res is Skill:
		learn_skill(res)
		return true
	return false

func _find_skill_resource_by_name(n: String) -> Skill:
	var dir := DirAccess.open("res://asset/skill")
	if dir:
		dir.list_dir_begin()
		var fn := dir.get_next()
		while fn != "":
			if fn.ends_with(".tres"):
				var path := "res://asset/skill/" + fn
				var r = load(path)
				if r and r is Skill:
					var s: Skill = r
					if str(s.name) == n:
						dir.list_dir_end()
						return s
			fn = dir.get_next()
		dir.list_dir_end()
	return null

#endregion

func is_alive() -> bool:
	return my_stat.HP.value > 0

func take_damage(amount: int, source: ActorController = null) -> void:
	var final := amount
	# for b in buffs:
	# 	final = b.modify_incoming_damage(final, self, source)
	print(my_name, " 受到伤害", final, "，来自 ", source.my_name)
	add_HP(-final)

func animate_take_damage_after(seconds: float, context: Dictionary) -> void:
	await get_tree().create_timer(seconds).timeout
	if context.get("is_hit"):
		if context.get("is_parry"):
			print(my_name, " 招架了")
			anim_player.play(&"defend")
		else:
			anim_player.play(&"take_damage")
	else:
		print(my_name, " 闪避了")
		#anim_player.play(&"ShanBi")
	anim_player.highlight_with_animation(UnitAnimatedSprite3D.HighLightType.ReceiveDamage, false)

# 序列化：导出完整角色信息
func serialize() -> Dictionary:
	var st: UnitStat = my_stat
	var base_vals: Array = []
	if st and st.base_attr and st.base_attr.attrs:
		for i in st.base_attr.attrs.size():
			base_vals.append(st.base_attr.attrs[i].value)
	var tags_out: Array = []
	if tags:
		for t in tags:
			tags_out.append(str(t))
	var skills_out: Array = []
	if skills:
		for s in skills:
			if s:
				var rp := (s as Resource).resource_path if s is Resource else ""
				skills_out.append({
					"name": str(s.name),
					"path": rp
				})
	return {
		"name": str(my_name),
		"sect": int(sect),
		"camp": int(camp),
		"team_id": int(team_id),
		"facing_direction": int(facing_direction),
		"ap": AP.value if AP else 0,
		"lv": st.LV.value if st and st.LV else 1,
		"hp": st.HP.value if st and st.HP else 0,
		"mp": st.MP.value if st and st.MP else 0,
		"base_attrs": base_vals,
		"gear": st.gear if st else {},
		"tags": tags_out,
		"skills": skills_out,
		"character_id": str(my_name), # 用唯一标识映射 .dch
	}

# 反序列化：从字典恢复角色状态
func deserialize(data: Dictionary) -> void:
	sect = data.get("sect", sect)
	camp = data.get("camp", camp)
	team_id = data.get("team_id", team_id)

	var fd := int(data.get("facing_direction", int(facing_direction)))
	match fd:
		0: facing_direction = FacingDirection.Right
		1: facing_direction = FacingDirection.Down
		2: facing_direction = FacingDirection.Left
		3: facing_direction = FacingDirection.Up
		_: facing_direction = FacingDirection.Right

	if AP:
		AP.set_value(int(data.get("ap", AP.value)))

	var st: UnitStat = my_stat
	if st and st.LV:
		st.LV.set_value(int(data.get("lv", st.LV.value)))

	# 基础属性先恢复，再刷新战斗属性
	var base_vals: Array = data.get("base_attrs", [])
	if st and st.base_attr and base_vals.size() == 5:
		for i in range(5):
			st.base_attr.attrs[i].set_value(int(base_vals[i]))

	# 装备字典
	if st:
		st.gear = data.get("gear", st.gear)
		st.update_all_by_base_attr()

	# 恢复当前 HP/MP（受最大值限制）
	if st and st.HP:
		st.HP.set_value(int(data.get("hp", st.HP.value)))
	if st and st.MP:
		st.MP.set_value(int(data.get("mp", st.MP.value)))

	# 标签
	var tags_in: Array = data.get("tags", [])
	tags = []
	for t in tags_in:
		tags.append(StringName(str(t)))

	# 角色资源
	var char_id = data.get("character_id", str(my_name))
	character = DialogicResourceUtil.get_character_resource(char_id as String)

	# 技能
	var skills_in: Array = data.get("skills", [])
	if skills_in and skills_in is Array:
		skills.clear()
		for it in skills_in:
			if it is Dictionary:
				var p := str(it.get("path", ""))
				var n := str(it.get("name", ""))
				var sk: Skill = null
				if not p.is_empty():
					var r = load(p)
					if r and r is Skill:
						sk = r
				if sk == null and not n.is_empty():
					sk = _find_skill_resource_by_name(n)
				if sk:
					skills.append(sk)
