extends Resource
class_name SceneData

@export var id: StringName = &"" # 方便调试或存档
@export var background: Texture2D
@export var music: AudioStream
@export var buttons: Array[SceneButtonData] = []

# 返回按钮相关（可选）
@export var show_back_button: bool = true
@export var back_button_texture: Texture2D
@export var back_button_position: Vector2 = Vector2(24, 24)
@export var back_button_size: Vector2 = Vector2(64, 64)
@export var back_button_tooltip: String = "返回"

# 布局缩放：用于适配不同分辨率（背景和按钮一起缩放）
@export var design_size: Vector2 = Vector2(1920, 1080)
@export var keep_aspect: bool = true
