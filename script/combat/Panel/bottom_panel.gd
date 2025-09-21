class_name BottomPanel extends Node

@onready var texture_button = $TextureButton
@onready var LV  = $Label_LV
@onready var STR = $Label_STR
@onready var CON = $Label_CON
@onready var AGI = $Label_AGI
@onready var WIL = $Label_WIL
@onready var INT = $Label_INT
@onready var HP_Bar = $HP_Bar
@onready var MP_Bar = $MP_Bar
@onready var info     = $bottom_info as Label
@onready var red_info = $temp_info   as Label

var _cur_actor: ActorController = null
var _tmp_info_timer: SceneTreeTimer = null

func _clear_info_tmp() -> void:
	red_info.text = ""
	info.show()
	_tmp_info_timer = null

func put_info_tmp(txt: String, play_seconds: float) -> void:
	if play_seconds < 0.1:
		return
	red_info.text = txt
	info.hide()
	# 如果当前有计时器在运行，取消它
	if _tmp_info_timer != null:
		_tmp_info_timer.disconnect(&"timeout", _clear_info_tmp)	
	# 创建新的计时器
	_tmp_info_timer = get_tree().create_timer(play_seconds)
	_tmp_info_timer.timeout.connect(_clear_info_tmp)

func put_info(txt: String) -> void:
	info.text = txt

func set_actor(actor: ActorController) -> void:
	if actor == null:
		return
	_cur_actor = actor
	texture_button.texture_normal = Game.g_actors.get_timeline_icon_by_actor_name(actor.my_name)
	# 刷新属性
	LV.text = str(_cur_actor.my_stat.LV.value)
	STR.text = str(_cur_actor.my_stat.base_attr.at(0))
	CON.text = str(_cur_actor.my_stat.base_attr.at(1))
	AGI.text = str(_cur_actor.my_stat.base_attr.at(2))
	WIL.text = str(_cur_actor.my_stat.base_attr.at(3))
	INT.text = str(_cur_actor.my_stat.base_attr.at(4))
	# 刷新HP和MP
	HP_Bar.max_value = _cur_actor.my_stat.HP.maximum
	MP_Bar.max_value = _cur_actor.my_stat.MP.maximum
	HP_Bar.value = _cur_actor.my_stat.HP.value
	MP_Bar.value = _cur_actor.my_stat.MP.value
	
