# 角色控制器
class_name ActorController extends Node

enum BrainType {
	AI,
	Player
	}
	
var anim_player: AnimatedSprite3D # 动画节点的引用
var my_stat    : UnitStat         # 数据
var AP         : AttributeBase    # 行动点

var brain    : = BrainType.AI     # 操控者
var camp     : = Game.Camp.Player # 阵营
var team_id  : = Game.TeamID.Red  # 队伍

var buffs    : Array[BuffBase]    # buff 列表
var actions  : Array[ActionBase]  # 待执行动作列表

var my_name  : StringName     # 角色名（唯一）
var base3d   : UnitBase3D     # 在场景中显示用

func _init(actor_name: StringName) -> void:
	my_name = actor_name
