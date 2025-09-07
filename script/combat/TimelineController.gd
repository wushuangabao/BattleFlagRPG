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
var set_array_map : Dictionary[HashSet, OrderedArray]

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
	set_array_map.clear()
	var actor_y_map : Dictionary[ActorController, float] = {}
	var actors := HashSet.new()
	var any_ready := false
	# 增加 AP
	for a in Game.g_combat.get_actors():
		if not a.is_alive():
			if texture_map.has(a):
				_on_actor_die(a) # 去除死亡角色的头像
			continue
		actors.append(a)
		if a.get_AP() >= AP_MAX:
			actor_y_map[a] = texture_map[a].position.y
			continue
		var gain = a.get_ap_gain_per_sec() * delta
		gain_ap_map[a] += gain
		if gain_ap_map[a] >= 1.0:
			gain_ap_map[a] -= 1.0
			a.add_AP(1)
		if a.get_AP() >= AP_THRESHOLD:
			ready_queue.push_back(a)
			any_ready = true
		actor_y_map[a] = btn_origin_y - (a.get_AP() + gain_ap_map[a]) * len_per_ap
	# 不让头像重叠
	# 首先为每个头像建立临时的重叠集
	var tmp : Dictionary[ActorController, HashSet]  # key: actor, value: 与 actor 重叠的或即将重叠的角色集合
	for cur_a in actors.to_array():
		var cur_set = null
		var cur_y := actor_y_map[cur_a]
		for a in actors.to_array():
			if a == cur_a:
				continue
			if abs(cur_y - actor_y_map[a]) < btn_spacing:
				if not tmp.has(a):
					if cur_set == null:
						cur_set = HashSet.new([cur_a])
					cur_set.append(a)
		if cur_set != null:
			tmp[cur_a] = cur_set
	# 把 tmp 填充到 set_array_map 中
	for cur_a in tmp:
		var hash_set = _is_in_setArrayMap(cur_a)
		if hash_set == null:
			hash_set = tmp[cur_a]
			set_array_map[hash_set] = OrderedArray.new(_sort_actor_by_ap_gain_speed)
			for a in hash_set.to_array():
				set_array_map[hash_set].append(a)
		else:
			for a in tmp[cur_a].to_array():
				if not hash_set.has(a):
					hash_set.append(a)
					set_array_map[hash_set].append(a)		
	# 设置各个角色的头像坐标
	for actor_set in set_array_map:
		var new_x := btn_origin_x
		for a in set_array_map[actor_set].get_data():
			var new_y = actor_y_map[a]
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
	# var new_x := btn_origin_x
	# if set_array_map.has(a.get_AP()):
	# 	ap.a
	if gradually:
		var current_p = texture_map[a].position
		var new_p = current_p
		new_p.y = new_y
		var time = absf(new_y - current_p.y) * 2 / timeline_h
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(texture_map[a], ^"position", new_p, time)
	else:
		
		texture_map[a].position.y = new_y

func _is_in_setArrayMap(a: ActorController):
	if set_array_map.size() > 0:
		for hash_set in set_array_map:
			if hash_set.has(a):
				return hash_set
	return null

func _sort_actor_by_ap_gain_speed(a1: ActorController, a2: ActorController) -> bool:
	var s1 := a1.get_ap_gain_per_sec()
	var s2 := a2.get_ap_gain_per_sec()
	if not is_equal_approx(s1, s2):
		return s1 < s2
	# 如果AP获得速度差不多，则根据名字排序
	var h1 := a1.my_name.hash()
	var h2 := a2.my_name.hash()
	if h1 == h2:
		return String(a1.my_name) < String(a2.my_name)
	else:
		return h1 < h2
