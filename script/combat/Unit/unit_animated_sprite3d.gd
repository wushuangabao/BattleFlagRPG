class_name UnitAnimatedSprite3D extends AnimatedSprite3D

enum HighLightType {
	Current,
	TargetRed,
	TargetGreen,
	ReceiveDamage,
	ReceiveHeal,
	ReceivePositiveBuff,
	ReceiveNegativeBuff,
}

@export var outline_color := Color(1.0, 0.9, 0.8, 0.75) # 默认发光颜色
@export var outline_width := 2.0 # 轮廓宽度
@export var outline_intensity := 1.0 # 轮廓强度

var mat: ShaderMaterial
var _prev_frame := -1

# 静态变量，控制所有实例是否使用着色器
static var global_use_shader := true

func _ready() -> void:
	sorting_offset = 1000.0  # 设置渲染层级，确保精灵始终在最前面显示
	if global_use_shader:
		_setup_shader()
	else:
		# 不启用 material_override 时 billboard 设置才会生效
		billboard = StandardMaterial3D.BILLBOARD_ENABLED

# 设置着色器
func _setup_shader():
	mat = ShaderMaterial.new()
	mat.shader = preload("res://scene/unit/unit.gdshader")
	material_override = mat
	# 默认不启用轮廓
	mat.set_shader_parameter("enable_outline", false)
	# 设置初始颜色和参数
	mat.set_shader_parameter("outline_color", outline_color)
	mat.set_shader_parameter("outline_width", outline_width)
	mat.set_shader_parameter("outline_intensity", outline_intensity)
	_apply_frame_texture()

func _process(_delta: float) -> void:
	# 只在使用着色器且帧变化时更新纹理
	if global_use_shader and _prev_frame != frame:
		_prev_frame = frame
		_apply_frame_texture()

func _apply_frame_texture():
	if not global_use_shader or sprite_frames == null:
		return
	var tex: Texture2D = sprite_frames.get_frame_texture(animation, frame)
	if tex and mat:
		mat.set_shader_parameter("u_frame_tex", tex)

# 轮廓发光效果
func outline_on(color: Color = outline_color):
	if global_use_shader and mat:
		mat.set_shader_parameter("enable_outline", true)
		mat.set_shader_parameter("outline_color", color)

func outline_off():
	if global_use_shader and mat:
		mat.set_shader_parameter("enable_outline", false)

# 设置轮廓颜色
func set_outline_color(color: Color):
	outline_color = color
	if global_use_shader and mat:
		mat.set_shader_parameter("outline_color", color)

# 纹理颜色混合控制函数
func color_tint_on(color: Color, strength: float = 0.5):
	if global_use_shader and mat:
		mat.set_shader_parameter("enable_color_tint", true)
		mat.set_shader_parameter("tint_color", color)
		mat.set_shader_parameter("tint_strength", strength)

func color_tint_off():
	if global_use_shader and mat:
		mat.set_shader_parameter("enable_color_tint", false)

# 设置颜色混合强度
func set_tint_strength(strength: float):
	if global_use_shader and mat:
		mat.set_shader_parameter("tint_strength", strength)

func highlight_on(t: HighLightType = HighLightType.Current) -> void:
	match t:
		HighLightType.Current:
			outline_on()
		HighLightType.TargetRed:
			color_tint_on(Color(1.0, 0.3, 0.3, 1.0))
		HighLightType.TargetGreen:
			color_tint_on(Color(0.3, 1.0, 0.3, 1.0))
		HighLightType.ReceiveDamage:
			color_tint_on(Color(1.0, 0.3, 0.3, 1.0), 0.7)  # 红色纹理混合，表示受到伤害
		HighLightType.ReceiveHeal:
			color_tint_on(Color(0.3, 1.0, 0.5, 1.0), 0.6)  # 绿色纹理混合，表示受到治疗
		HighLightType.ReceivePositiveBuff:
			outline_on(Color(0.3, 1.0, 0.3, 0.5))  # 绿光描边，表示受到增益buff
		HighLightType.ReceiveNegativeBuff:
			outline_on(Color(0.8, 0.3, 1.0, 0.5))  # 紫光描边，表示受到减益buff

func highlight_off() -> void:
	outline_off()
	color_tint_off()

# 带有动画效果的高亮显示
func highlight_with_animation(t: HighLightType, turn_off: bool, duration: float = 1.0) -> void:
	highlight_on(t)
	match t:
		HighLightType.ReceiveDamage:
			_animate_damage_effect(duration, turn_off)
		HighLightType.ReceiveHeal:
			_animate_heal_effect(duration, turn_off)
		HighLightType.ReceivePositiveBuff:
			_animate_positive_buff_effect(duration, turn_off)
		HighLightType.ReceiveNegativeBuff:
			_animate_negative_buff_effect(duration, turn_off)
		_:
			_animate_default_highlight(duration, turn_off)

# 伤害效果动画：快速闪烁红色纹理
func _animate_damage_effect(duration: float, turn_off: bool) -> void:
	var tween = create_tween()
	var duration_per = duration * 0.25
	tween.set_loops(2)
	tween.tween_method(_set_tint_strength, 0.5, 1.0, duration_per)
	tween.tween_method(_set_tint_strength, 1.0, 0.5, duration_per)
	if turn_off:
		tween.tween_callback(highlight_off)

# 治疗效果动画：柔和的绿色纹理脉冲
func _animate_heal_effect(duration: float, turn_off: bool) -> void:
	var tween = create_tween()
	tween.tween_method(_set_tint_strength, 0.6, 0.9, 0.5)
	tween.tween_method(_set_tint_strength, 0.9, 0.6, 0.5)
	tween.tween_interval(duration - 1.0)
	if turn_off:
		tween.tween_callback(highlight_off)

# 增益buff效果动画：绿光描边渐强
func _animate_positive_buff_effect(duration: float, turn_off: bool) -> void:
	var tween = create_tween()
	tween.tween_method(_set_outline_intensity, 1.0, 2.0, 0.5)
	tween.tween_interval(duration - 1.0)
	tween.tween_method(_set_outline_intensity, 2.0, 1.0, 0.5)
	if turn_off:
		tween.tween_callback(highlight_off)

# 减益buff效果动画：紫光描边波动
func _animate_negative_buff_effect(duration: float, turn_off: bool) -> void:
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_method(_set_outline_intensity, 1.0, 1.5, 0.15)
	tween.tween_method(_set_outline_intensity, 1.5, 1.0, 0.15)
	tween.tween_interval(duration - 1.2)
	if turn_off:
		tween.tween_callback(highlight_off)

# 默认高亮动画
func _animate_default_highlight(duration: float, turn_off: bool) -> void:
	var tween = create_tween()
	tween.tween_interval(duration)
	if turn_off:
		tween.tween_callback(highlight_off)

# 设置轮廓强度的辅助函数
func _set_outline_intensity(intensity: float) -> void:
	if global_use_shader and mat:
		mat.set_shader_parameter("outline_intensity", intensity)

# 设置纹理混合强度的辅助函数
func _set_tint_strength(strength: float) -> void:
	if global_use_shader and mat:
		mat.set_shader_parameter("tint_strength", strength)
