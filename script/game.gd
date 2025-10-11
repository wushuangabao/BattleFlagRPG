# 游戏中的常量和常用静态函数
class_name Game

const CONFIG_PATH := "user://settings.cfg"
const SAVE_FOLDER := "user://saves/"

const Debug = 1
const pi_4 = PI / 4.0  # 45度
const pi_2 = PI / 2.0  # 90度

const MAX_LEVEL = 50
const MAX_HP    = 3000
const MAX_MP    = 3000
const MAX_ATK   = 1000
const MAX_DEF   = 1000
const BASE_SPD  = 5

# TileMap中每格的像素尺寸（与TileSet一致）
const cell_pixel_size: Vector2i = Vector2i(64, 64)

# 每格在3D世界中的对应长度
const cell_world_size: Vector2 = Vector2(1.0, 1.0) # x对应世界X，y对应世界Z

static var g_luban := Luban.new()
static var g_event := TypeEventSystem.new()
static var g_combat := BattleSystem.new()
static var g_actors : ActorManager = null
static var g_scenes : SceneManager = null
static var g_runner : StoryRunner  = null

static var _base_attrs
static func get_base_attrs() -> Array:
	if _base_attrs:
		return _base_attrs as Array
	else:
		_base_attrs = g_luban.get_base_attrs() as Array
		return _base_attrs

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
