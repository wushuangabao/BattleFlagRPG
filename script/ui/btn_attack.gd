extends TextureButton

@export var skill : Skill

var _default_skill : Skill = null

func _ready():
	_default_skill = skill
	_apply_skill_to_button()

func set_skill(s: Skill) -> void:
	# 允许传入 null：使用默认技能作为回退
	if s == null:
		skill = _default_skill
	else:
		skill = s
	_apply_skill_to_button()

func _apply_skill_to_button() -> void:
	if skill and skill.icon:
		texture_normal = skill.icon
		var mask_texture = BitMap.new()
		var img = texture_normal.get_image()
		if img:
			mask_texture.create_from_image_alpha(img)
			texture_click_mask = mask_texture
		disabled = false
	else:
		# 没有技能或没有图标，禁用按钮
		texture_normal = null
		texture_click_mask = null
		disabled = true

func _on_pressed() -> void:
	if skill == null:
		return
	Game.g_event.send_event("event_chose_action", ActionAttack.new(skill))
