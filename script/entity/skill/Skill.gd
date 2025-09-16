class_name Skill extends Resource

var id : int
@export var name : String
@export var icon : Texture2D
@export var tags : Array[StringName] # “刀法”, “外攻”

@export var cost : Dictionary[StringName, int]
@export var cool_down : float # 使用后隔几秒可以再次使用
@export var charges   : int   # 一场战斗中可以使用多少次

@export var cast_time : float # 需要等待多少秒后才生效
@export var area_range: SkillAreaShape # 技能的影响范围
@export var area_chose: SkillAreaShape # 目标的选择范围

@export var filters : Array[StringName] # 标签过滤（比如不可对隐身）

@export var effects : Array[EffectBase] # 按序执行效果，可插入条件判断

var scaling # 伤害公式参数
var hit_formula # 命中公式引用（可在 resolver 中按标签选择）
