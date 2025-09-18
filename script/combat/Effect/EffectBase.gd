## 技能效果基类
## 
## 用于在技能使用时按序执行各种效果，支持条件判断和标签系统
## 所有具体的效果类型都应该继承此基类并实现execute方法
class_name EffectBase extends Resource

## 效果类型枚举
enum EffectType {
	Damage,    # 伤害（支持多段、溅射）
	Heal,      # 治疗
	AddBuff,   # 施加状态
	Cure,      # 驱散状态（按标签）
	Move,      # 位移（推拉、突进、闪现）
	Resource,  # 资源变动（回复/消耗 MP/AP/护盾）
	Spwan,     # 召唤物
	Custom     # 自定义脚本入口（高自由度）
}

## 效果类型
@export var my_type : EffectType

## 目标角色（在执行时设置）
var target : ActorController

## 施法者（在执行时设置）
var caster : ActorController

## 执行条件数组（目标血量阈值、是否暴击、是否命中、是否被特定Buff等）
@export var conditions : Array[ConditionBase] = []

## 效果标签，用于UI提示与交互等
@export var tags : Array[StringName] = []

## 效果名称（用于调试和UI显示）
@export var effect_name : String = ""

## 效果描述（用于UI显示）
@export var description : String = ""

## 检查所有条件是否满足
## @param context: 执行上下文，包含相关信息（如是否暴击、伤害值等）
## @return: 如果所有条件都满足返回true，否则返回false
func check_conditions(context: Dictionary = {}) -> bool:
	for condition in conditions:
		if not condition.is_satisfied(target, caster, context):
			return false
	return true

## 执行效果的虚拟方法
## 子类必须重写此方法来实现具体的效果逻辑
## @param context: 执行上下文，包含相关信息
## @return: 执行结果，可以包含伤害值、治疗量等信息
func execute(_context: Dictionary = {}) -> Dictionary:
	push_error("EffectBase.execute() must be overridden in subclass")
	return {}

## 获取效果的预览信息（用于UI显示）
## @return: 包含效果预览信息的字典
func get_preview_info() -> Dictionary:
	return {
		"name": effect_name,
		"description": description,
		"type": my_type,
		"tags": tags
	}