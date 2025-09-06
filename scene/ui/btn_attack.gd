extends TextureButton

func _ready():
	var mask_texture = BitMap.new()
	mask_texture.create_from_image_alpha(texture_normal.get_image())
	texture_click_mask = mask_texture
