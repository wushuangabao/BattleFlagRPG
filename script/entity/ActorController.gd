# 角色控制器
class_name ActorController extends AbstractController

var my_stat  : UnitStat         # 数据
var AP       : AttributeBase    # 行动点
var tmp_timeline_y : float      # 在 timeline 上头像的 y 坐标

var camp     : = Game.Camp.Player # 阵营
var team_id  : = Game.TeamID.Red  # 队伍

var tags     : Array[StringName]
var buffs    : Array[BuffBase]    # buff 列表
var actions  : Array[ActionBase]  # 待执行动作列表

@export var my_name  : StringName     # 角色名（唯一）
@export var base3d   : UnitBase3D     # 在场景中显示用
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

 # 读取存档或者初始化数值表
func set_actor_data(actor_name) -> void:
	my_name = actor_name
	my_stat = UnitStat.new(self)
	print("角色基础属性数据初始化完毕 - ", actor_name)

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
