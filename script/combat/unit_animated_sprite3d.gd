class_name UnitAnimatedSprite3D extends AnimatedSprite3D

@export var hover_tint := Color(1, 1, 1, 1) # 对Sprite超过1是无效的
@export var normal_tint := Color(0.66, 0.66, 0.66, 0.95)

#var mat: ShaderMaterial
#
#func _ready() -> void:
	#mat = ShaderMaterial.new()
	#mat.shader = preload("res://scene/unit/unit.gdshader")
	#material_override = mat
	#_apply_frame_texture()
#
#func _process(_delta: float) -> void:
	## 可在侦测到 frame 变化时才更新（例如缓存上一次的 frame 索引）
	#_apply_frame_texture()
#
#func _apply_frame_texture():
	#if sprite_frames == null:
		#return
	#var tex: Texture2D = sprite_frames.get_frame_texture(animation, frame)
	#if tex:
		#mat.set_shader_parameter("u_frame_tex", tex)

func highlight_on():
	modulate = hover_tint

func highlight_off():
	modulate = normal_tint
