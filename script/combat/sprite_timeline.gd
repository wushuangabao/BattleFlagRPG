extends TextureButton

@export var hover_tint: Color = Color(1.2, 1.2, 1.2, 1) # 悬停时颜色
@export var normal_tint: Color = Color(1, 1, 1, 1)     # 常态颜色
@export var duration: float = 0.2                     # 渐变时长

var tween: Tween

func _ready() -> void:
	modulate = normal_tint
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_tween_modulate(hover_tint)

func _on_mouse_exited() -> void:
	_tween_modulate(normal_tint)

func _tween_modulate(target: Color, d: float = duration) -> void:
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate", target, d)
