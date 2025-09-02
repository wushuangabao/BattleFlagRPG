# 游戏中的常量和常用静态函数
class_name Game

const Debug = 1

# TileMap中每格的像素尺寸（与TileSet一致）
const cell_pixel_size: Vector2i = Vector2i(64, 64)

# 每格在3D世界中的对应长度
const cell_world_size: Vector2 = Vector2(1.0, 1.0) # x对应世界X，y对应世界Z

# 预加载常用场景，避免频繁加载
# 这些场景在 goto_scene 中第一次实例化之后会被缓存
const scene_cached: Dictionary = {
	BigMap = preload("res://scene/ui/BigMap/BigMap.tscn"),
	BattleScene = preload("res://scene/combat/BattleScene.tscn")
}

const global_node_path: Dictionary = {
	SceneManager = "/root/Game/GameRoot"
}

static func scene_manager_path() -> String:
	return global_node_path["SceneManager"]
