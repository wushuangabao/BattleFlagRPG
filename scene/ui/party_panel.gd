extends Control
class_name PartyPanel

@onready var search_box: LineEdit = $MarginContainer/VBoxContainer/Toolbar/Search
@onready var sort_option: OptionButton = $MarginContainer/VBoxContainer/Toolbar/Sort
@onready var sect_filter: OptionButton = $MarginContainer/VBoxContainer/Toolbar/Filter
@onready var count_label: Label = $MarginContainer/VBoxContainer/Toolbar/Count
@onready var scroll: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var cards_root: VFlowContainer = $MarginContainer/VBoxContainer/ScrollContainer/CardsRoot

# 卡片预制
@export var member_card_scene: PackedScene

# 缓存显示列表
var _filtered: Array[ActorController] = []

func _ready() -> void:
	_setup_sort_options()
	_setup_filter_options()
	_connect_signals()
	_refresh()

func _connect_signals() -> void:
	Game.g_event.register_event("party_changed", _refresh)
	Game.g_event.register_event("member_updated", _on_member_updated) # todo 发送事件
	search_box.text_changed.connect(func(_t): _refresh())
	sort_option.item_selected.connect(func(_i): _refresh())
	sect_filter.item_selected.connect(func(_i): _refresh())

func _setup_sort_options() -> void:
	sort_option.clear()
	sort_option.add_item("等级", 0)  # level desc
	sort_option.add_item("姓名", 1)  # name asc
	sort_option.add_item("门派", 2)  # sect asc
	sort_option.add_item("生命", 3)  # hp desc

func _setup_filter_options() -> void:
	sect_filter.clear()
	sect_filter.add_item("全部", -1)
	# 动态收集现有门派
	var sects := {}
	for m in Game.g_actors.get_all_members():
		sects[m.sect] = true
	for s in sects.keys():
		sect_filter.add_item(s)

func _apply_sort(arr: Array[ActorController]) -> void:
	var mode := sort_option.get_selected_id()
	match mode:
		0: arr.sort_custom(func(a, b): return a.level > b.level)
		1: arr.sort_custom(func(a, b): return a.display_name < b.display_name)
		2: arr.sort_custom(func(a, b): return a.sect < b.sect if a.sect != b.sect else a.display_name < b.display_name)
		3: arr.sort_custom(func(a, b): return a.hp > b.hp)
		_: pass

func _apply_filter() -> void:
	var all := Game.g_actors.get_all_members()
	var q := search_box.text.strip_edges().to_lower()
	var sect_sel_text := "" if sect_filter.get_selected_id() == -1 else sect_filter.get_item_text(sect_filter.get_selected())
	_filtered.clear()
	for m in all:
		if sect_sel_text != "" and m.sect != sect_sel_text:
			continue
		if q != "":
			var combined := ("%s %s %s" % [m.display_name, m.sect, m.note]).to_lower()
			if not combined.find(q) >= 0:
				continue
		_filtered.append(m)
	_apply_sort(_filtered)

func _clear_cards() -> void:
	for c in cards_root.get_children():
		c.queue_free()

func _refresh() -> void:
	_setup_filter_options() # 门派列表随成员变化刷新
	_apply_filter()
	_clear_cards()
	for m in _filtered:
		var card := member_card_scene.instantiate()
		cards_root.add_child(card)
		card.set_member(m)
		# 可选择连接点击信号打开详情
		card.member_clicked.connect(_on_member_clicked)
	count_label.text = "成员：%d" % _filtered.size()

func _on_member_updated(id: String) -> void:
	# 局部刷新：找到对应卡片更新
	for c in cards_root.get_children():
		if c.member and c.member.id == id:
			c.refresh()
			break

func _on_member_clicked(member: ActorController) -> void:
	# 打开详情面板（可选独立场景）
	var dlg := preload("res://scene/ui/PartyMemberCard.tscn").instantiate()
	add_child(dlg)
	dlg.popup_centered_ratio(0.6)
	dlg.set_member(member)
