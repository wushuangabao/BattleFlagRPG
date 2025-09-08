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

func _enter_tree() -> void:
	print("角色已经加载到树中 ", my_name)
	my_stat = UnitStat.new(self)
	AP = AttributeBase.new(0, TimelineController.AP_MAX)
	set_architecture(CombatArchitecture.new(my_stat))

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
	if my_name == &"test_actor":
		return 5.0
	return 4.0

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
