# 角色控制器
class_name ActorController extends AbstractController

enum BrainType {
	AI,
	Player
	}

var my_stat    : UnitStat         # 数据
var AP         : AttributeBase    # 行动点

var brain    : = BrainType.AI     # 操控者
var camp     : = Game.Camp.Player # 阵营
var team_id  : = Game.TeamID.Red  # 队伍

var buffs    : Array[BuffBase]    # buff 列表
var actions  : Array[ActionBase]  # 待执行动作列表

@export var my_name  : StringName     # 角色名（唯一）
@export var base3d   : UnitBase3D     # 在场景中显示用
@export var anim_player: AnimatedSprite3D # 动画节点的引用

func _enter_tree() -> void:
	my_stat = UnitStat.new(self)
	set_architecture(CombatArchitecture.new(my_stat))
	my_stat.HP.register_and_refresh(
		func(hp):
			print("ActorController 收到信号 HP = ", hp)
	)

func add_HP(v: int):
	my_stat.HP.value += v

func add_MP(v: int):
	my_stat.MP.value += v
