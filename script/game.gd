# 游戏中的常量和常用静态函数
class_name Game

const Debug = 1

# TileMap中每格的像素尺寸（与TileSet一致）
const cell_pixel_size: Vector2i = Vector2i(64, 64)

# 每格在3D世界中的对应长度
const cell_world_size: Vector2 = Vector2(1.0, 1.0) # x对应世界X，y对应世界Z

static var g_combat := BattleController.new()
static var g_actors := ActorManager.new()

# 预加载常用场景，避免频繁加载
# 这些场景在 goto_scene 中第一次实例化之后会被缓存
const scene_cached: Dictionary = {
	BigMap = preload("res://scene/ui/BigMap/BigMap.tscn"),
	BattleScene = preload("res://scene/combat/BattleScene.tscn")
}

# 节点路径表
const global_node_path: Dictionary = {
	SceneManager = "/root/Game/GameRoot"
}

static func scene_manager_path() -> String:
	return global_node_path["SceneManager"]

# 阵营
enum Camp {
	Player,
	Neutral,
	Enemy
	}

# 队伍
const MAX_TEAM_SIZE := 5
enum TeamID {
	Red,
	Yellow,
	Blue,
	Green,
	White,
	Black
	}

static func is_mouse_in_viewport(vp: Viewport) -> bool:
	return vp.get_visible_rect().has_point(vp.get_mouse_position())