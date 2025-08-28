extends RefCounted
class_name Game

# 预加载常用场景，避免频繁加载
# 这些场景在 goto_scene 中第一次实例化之后会被缓存
const scene_cached: Dictionary = {
	BigMap = preload("res://scene/ui/BigMap/BigMap.tscn"),
    BattleScene = preload("res://scene/combat/BattleScene.tscn")
}