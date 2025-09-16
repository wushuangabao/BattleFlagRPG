extends TextureButton

@export var skill : Skill

func _ready():
	texture_normal = skill.icon
	var mask_texture = BitMap.new()
	mask_texture.create_from_image_alpha(texture_normal.get_image())
	texture_click_mask = mask_texture

func _on_pressed() -> void:
	Game.g_event.send_event("event_chose_action", ActionAttack.new(skill))
