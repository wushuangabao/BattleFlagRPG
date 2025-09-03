# 角色管理器
class_name ActorController extends Node

enum BrainType {
	AI,
	Player
	}

var stat     : UnitStat
var AP       : AttributeBase      # 行动点

var brain    : = BrainType.AI     # 操控者
var camp     : = Game.Camp.Player # 阵营
var team_id  : = Game.TeamID.Red  # 队伍

var buffs    : Array[BuffBase]    # buff 列表
var actions  : Array[ActionBase]  # 待执行动作列表
