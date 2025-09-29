extends Resource
class_name SceneData

@export var id: StringName = &"" # 方便调试或存档
@export var background: Texture2D
@export var music: AudioStream
@export var buttons: Array[SceneButtonData] = []

# 返回按钮相关
@export var show_back_button: bool = true
@export var back_button_texture: Texture2D
@export var back_button_tooltip: String = "返回"

# 关联的故事节点
@export var story_choices: Array[StoryChoicePort]
