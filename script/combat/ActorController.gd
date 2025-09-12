# 角色控制器
class_name ActorController extends AbstractController

var my_stat  : UnitStat         # 数据
var AP       : AttributeBase    # 行动点
var tmp_timeline_y : float      # 在 timeline 上头像的 y 坐标

var camp     : = Game.Camp.Player # 阵营
var team_id  : = Game.TeamID.Red  # 队伍

var buffs    : Array[BuffBase]    # buff 列表
var actions  : Array[ActionBase]  # 待执行动作列表

@export var my_name  : StringName     # 角色名（唯一）
@export var base3d   : UnitBase3D     # 在场景中显示用
@export var anim_player: UnitAnimatedSprite3D # 动画节点的引用

enum ActorState {
	Idle, DoAction
}

var _state : ActorState = ActorState.Idle
var _action: ActionBase = null

func get_state() -> ActorState:
	return _state

signal begin_to_do_action
signal end_doing_action

var action:
	get:
		return _action
	set(new_action):
		if _action == null:
			_state = ActorState.DoAction
			if new_action.execute(self) == ActionBase.ActionState.Running:
				_action = new_action
				begin_to_do_action.emit(new_action)
			else:
				_state = ActorState.Idle # 动作执行一瞬间就结束了，不用发信号

 # 读取存档或者初始化数值表
func set_actor_data(actor_name) -> void:
	my_name = actor_name
	my_stat = UnitStat.new(self)
	print("角色基础属性数据初始化完毕 - ", actor_name)

func _enter_tree() -> void:
	print("角色已经加载到树中 ", my_name)
	my_stat = UnitStat.new(self)
	AP = AttributeBase.new(self, 0, TimelineController.AP_MAX)
	Game.g_combat.get_architecture().register_actor(self)

func _exit_tree() -> void:
	print("角色已从树中移除 ", my_name)
	Game.g_combat.get_architecture().unregister_actor(self)

func _process(delta: float) -> void:
	if _state == ActorState.DoAction:
		if _action == null:
			push_error("角色状态是DoAction但_action为空！")
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

func add_MP(v: int) -> void:
	my_stat.MP.set_value(my_stat.MP.value + v)

func add_AP(v: int) -> void:
	AP.set_value(AP.value + v)

func pay_AP(v: int) -> void:
	AP.set_value(AP.value - v)

func get_AP() -> int:
	return AP.value

func get_ap_gain_per_sec() -> float:
	return Game.BASE_SPD * (1 + my_stat.SPD.value)

func add_buff(buf: BuffBase) -> void:
	buffs.push_back(buf)

func add_action(act: ActionBase) -> void:
	actions.push_back(act)

func is_alive() -> bool:
	return my_stat.HP.value > 0

func take_damage(amount: int, source: ActorController = null) -> void:
	var final := amount
	# for b in buffs:
	# 	final = b.modify_incoming_damage(final, self, source)
	print(my_name, " 受到伤害", final, "，来自 ", source)
	add_HP(-final)
