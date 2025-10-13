class_name PartyMemberCard extends PanelContainer

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
	if not member: return
	portrait.texture = member.portrait
	name_label.text = member.display_name
	lv_label.text = "Lv.%d" % member.level
	sect_label.text = member.sect
	hp_bar.max_value = member.max_hp
	hp_bar.value = member.hp
	hp_bar.tooltip_text = "%d / %d" % [member.hp, member.max_hp]
	mp_bar.max_value = member.max_mp
	mp_bar.value = member.mp
	mp_bar.tooltip_text = "%d / %d" % [member.mp, member.max_mp]
	_refresh_states()

func _refresh_states() -> void:
	for c in states_root.get_children():
		c.queue_free()
	for s in member.states:
		var icon := TextureRect.new()
		icon.texture = state_icons.get(s, null)
		icon.custom_minimum_size = Vector2(16,16)
		icon.tooltip_text = s
		states_root.add_child(icon)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("member_clicked", member)
