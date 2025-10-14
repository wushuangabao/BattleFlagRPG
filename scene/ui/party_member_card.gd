class_name PartyMemberCard extends ColorRect

signal member_clicked(member: ActorController)

@onready var portrait: TextureRect = $HBoxContainer/Portrait
@onready var name_label: Label = $HBoxContainer/VBoxContainer/HBoxContainer/Name
@onready var lv_label: Label = $HBoxContainer/VBoxContainer/HBoxContainer/Lv
@onready var sect_label: Label = $HBoxContainer/VBoxContainer/HBoxContainer/Sect
@onready var hp_bar: TextureProgressBar = $HBoxContainer/VBoxContainer/HPbar
@onready var mp_bar: TextureProgressBar = $HBoxContainer/VBoxContainer/MPbar
@onready var states_root: HBoxContainer = $HBoxContainer/VBoxContainer/StatesRoot
@onready var detail_btn: Button = $HBoxContainer/VBoxContainer/Detail

var member: ActorController

# 用于状态小图标的映射（占位）
var state_icons := {
	#"中毒": preload("res://ui/icons/state_poison.png"),
	#"流血": preload("res://ui/icons/state_bleed.png"),
	#"护体": preload("res://ui/icons/state_shield.png")
}

func _ready() -> void:
	detail_btn.pressed.connect(func(): emit_signal("member_clicked", member))
	# 整张卡可点击
	gui_input.connect(_on_gui_input)

func set_member(data: ActorController) -> void:
	member = data
	refresh()

func refresh() -> void:
	if not member or not member.character:
		return
	# 读取头像图片路径（兼容 export_overrides.image 或 path 字段）
	var info: Dictionary = member.character.get_portrait_info(member.character.default_portrait)
	var tex_path := ""
	if info.has("export_overrides") and info.export_overrides.has("image"):
		tex_path = str(info.export_overrides.image)
	elif info.has("path"):
		tex_path = str(info.path)
	# 去除可能存在的引号
	tex_path = tex_path.strip_edges().trim_prefix('"').trim_suffix('"')
	var tex := load(tex_path)
	if tex is Texture2D:
		portrait.texture = tex
	else:
		push_warning("加载头像失败: " + tex_path)
	name_label.text = member.character.get_display_name_translated()
	lv_label.text = "Lv.%d" % member.my_stat.LV.value
	sect_label.text = Game.SectNames[member.sect]
	hp_bar.max_value = member.my_stat.HP.maximum
	hp_bar.value = member.my_stat.HP.value
	hp_bar.tooltip_text = "%d / %d" % [hp_bar.value, hp_bar.max_value]
	mp_bar.max_value = member.my_stat.MP.maximum
	mp_bar.value = member.my_stat.MP.value
	mp_bar.tooltip_text = "%d / %d" % [mp_bar.value, mp_bar.max_value]
	#_refresh_states()

func _refresh_states() -> void:
	for c in states_root.get_children():
		c.queue_free()
	for s in member.states:
		var icon := TextureRect.new()
		icon.texture = state_icons.get(s, null)
		icon.custom_minimum_size = Vector2(64, 96)
		icon.tooltip_text = s
		states_root.add_child(icon)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("member_clicked", member)
