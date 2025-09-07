class_name TimelineController extends ProgressBar

const AP_THRESHOLD := 6
const AP_MAX := 6
const btn_origin_x := 11.5  # 头像初始横坐标
const btn_origin_y := 568.0 # 头像初始纵坐标 = size.y - 32
const btn_spacing := 66.0   # 头像横向排列间距 = 64 + 2
const timeline_h := 590.0   # 行动条高度 = size.y - 10

signal actor_ready # 通知到 BattleSystem._turn_controller.do_turn

@export var packed_sprite : PackedScene

var running     : bool
var len_per_ap  : float
var ready_queue : Array[ActorController] = []
var gain_ap_map : Dictionary[ActorController, float]
var texture_map  : Dictionary[ActorController, TextureButton]
var ap_array_map : Dictionary[int, OrderedArray]

func _ready() -> void:
	running = false
	max_value = AP_MAX
	value = AP_THRESHOLD
	len_per_ap = timeline_h / AP_MAX

func _physics_process(delta: float) -> void:
	if not running:
		return
	if ready_queue.size() > 0:
		running = false
		actor_ready.emit(ready_queue.pop_front())
		return
	ap_array_map.clear()
	var any_ready := false
	var actors = Game.g_combat.get_actors()
	# 增加 AP
	for a in actors:
		if not a.is_alive():
			if texture_map.has(a):
				_on_actor_die(a)
			continue
		if a.get_AP() >= AP_THRESHOLD:
			continue
		var gain = a.get_ap_gain_per_sec() * delta
		gain_ap_map[a] += gain
		if gain_ap_map[a] >= 1.0:
			gain_ap_map[a] -= 1.0
			a.add_AP(1)
		if a.get_AP() >= AP_THRESHOLD:
			ready_queue.push_back(a)
			any_ready = true
	# 把 AP 相等的角色排个序（不让头像重叠在一起）
	for a in actors:
		var a_ap := a.get_AP()
		if not ap_array_map.has(a_ap):
			ap_array_map[a_ap] = OrderedArray.new(_sort_actor_by_name)
		ap_array_map[a_ap].append(a)
	# 设置各个角色的头像坐标
	for ap in ap_array_map:
		var new_x := btn_origin_x
		for a in ap_array_map[ap]:
			var new_y = btn_origin_y - (ap + gain_ap_map[a]) * len_per_ap
			texture_map[a].position.y = new_y
			texture_map[a].position.x = new_x
			new_x += btn_spacing
	# 等待回合行动
	if any_ready and ready_queue.size() > 0:
		running = false
		actor_ready.emit(ready_queue.pop_front())

func _on_actor_die(a: ActorController) -> void:
	ready_queue.erase(a)
	if gain_ap_map.has(a):
		gain_ap_map.erase(a)
	if texture_map.has(a):
		texture_map.erase(a)

func start(actors_list: Array[ActorController]) -> void:
	for a in actors_list:
		a.AP._value = 0 # 这样赋值可以不触发事件
		#a.AP.register(func(new_ap):
			#print("Timeline 接收到AP变更信号：", new_ap, " - ", a.my_name)
		#)
		var btn = packed_sprite.instantiate() as TextureButton
		btn.position.x = btn_origin_x
		btn.position.y = btn_origin_y
		add_child(btn)
		gain_ap_map[a] = 0.0
		texture_map[a] = btn
	ready_queue.clear()
	running = true

func resume() -> void:
	running = true

func move_actor_btn(a: ActorController, gradually: bool = false) -> void:
	var new_y = btn_origin_y - (a.get_AP() + gain_ap_map[a]) * len_per_ap
	var new_x := btn_origin_x
	
	var oa := OrderedArray.new(_sort_actor_by_name)
	oa.append(a)
	var xa := {a : new_x}
	var actors := Game.g_combat.get_actors()
	for actor in actors:
		if texture_map.has(actor) and absf(new_y - texture_map[a].position.y) < 32.0:
			xa[a] = texture_map[a].position.x
			oa.append(actor)
	var x_ordered = btn_origin_x
	for a_orderd in oa.get_data():
		if texture_map[a_orderd].position.x != x_ordered:
			texture_map[a_orderd].position.x = x_ordered
		x_ordered += btn_spacing
	if gradually:
		var current_p = texture_map[a].position
		var new_p = current_p
		new_p.y = new_y
		var time = absf(new_y - current_p.y) * 2 / timeline_h
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(texture_map[a], ^"position", new_p, time)
	else:
		
		texture_map[a].position.y = new_y

func _sort_actor_by_name(a1: ActorController, a2: ActorController) -> bool:
	var h1 := a1.my_name.hash()
	var h2 := a2.my_name.hash()
	if h1 == h2:
		return String(a1.my_name) < String(a2.my_name)
	else:
		return h1 < h2
