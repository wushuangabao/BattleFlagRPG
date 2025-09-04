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
var sprites  : Dictionary         # 动画资源路径表

var my_name  : StringName     # 角色名（唯一）
var base3d   : UnitBase3D     # 在场景中显示用

func set_animsprite_node(a: AnimatedSprite3D) -> void:
	anim_player = a
	var frames := SpriteFrames.new()
	var aniname := &"run"
	frames.add_animation(aniname)
	frames.set_animation_speed(aniname, 5) # 每秒播放 5 帧
	frames.set_animation_loop(aniname, true) # 设置为循环播放
	var frame_textures := [
		load("res://asset/png/character/run_animation/run-1.png"),
		load("res://asset/png/character/run_animation/run-2.png"),
		load("res://asset/png/character/run_animation/run-3.png"),
		load("res://asset/png/character/run_animation/run-4.png"),
		load("res://asset/png/character/run_animation/run-5.png"),
		load("res://asset/png/character/run_animation/run-6.png"),
		load("res://asset/png/character/run_animation/run-7.png"),
		load("res://asset/png/character/run_animation/run-8.png")
	]
	for texture in frame_textures:
		frames.add_frame(aniname, texture)
	anim_player.sprite_frames = frames

func _init(actor_name: StringName) -> void:
	my_name = actor_name
	sprites[&"run"] = Texture2D
