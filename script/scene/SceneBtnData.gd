extends Resource
class_name SceneButtonData

@export var name: StringName = &""
@export var texture: Texture2D
@export var tooltip: String = ""
# 点击后要跳转的场景资源
@export var target_scene: SceneData
# 可选：自定义音效
@export var click_sound: AudioStream
# 可选：是否可见/可用的条件（用简单开关，或留给外部系统）
@export var enabled: bool = true
@export var visible: bool = true
