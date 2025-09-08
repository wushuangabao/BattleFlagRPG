class_name UnitAnimatedSprite3D extends AnimatedSprite3D

@export var hover_tint := Color(1, 1, 1, 1) # 对Sprite超过1是无效的
@export var normal_tint := Color(0.75, 0.75, 0.75, 0.9)

func _ready() -> void:
	modulate = normal_tint

func highlight_on():
	modulate = hover_tint

func highlight_off():
	modulate = normal_tint
