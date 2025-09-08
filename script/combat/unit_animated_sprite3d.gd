class_name UnitAnimatedSprite3D extends AnimatedSprite3D

@export var hover_tint := Color(1, 1, 1, 1) # 对Sprite超过1是无效的
@export var normal_tint := Color(0.66, 0.66, 0.66, 0.95)

func highlight_on():
	modulate = hover_tint

func highlight_off():
	modulate = normal_tint
