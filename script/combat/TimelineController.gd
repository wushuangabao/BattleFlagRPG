class_name TimelineController extends ProgressBar

const AP_THRESHOLD := 5
const AP_MAX := 10
const btn_origin_x := 11.5  # 头像初始横坐标
const btn_origin_y := 568.0 # 头像初始纵坐标 = size.y - 32
const btn_spacing  := 64.0  # 头像开始“跳跃”时纵向间距dy的最大值（跳跃高度 = 33 * cos(btn_jump_arg * dy) + 32）
const btn_jump_arg := 0.045
const timeline_h := 590.0   # 行动条高度 = size.y - 10

signal actor_ready # 通知到 BattleSystem._turn_controller.do_turn

@export var packed_sprite : PackedScene
@export var packed_arrow : PackedScene

var running     : bool
var btn_moving  : bool
var len_per_ap  : float
var arrow_anmi  : AnimatedSprite2D
var ready_actor : HashSet
var ready_queue : Array[ActorController] = []
var gain_ap_map : Dictionary[ActorController, float]
var texture_map : Dictionary[ActorController, TextureButton]

func _init() -> void:
	running = false
	btn_moving = false
	max_value = AP_MAX
	value = AP_THRESHOLD
	len_per_ap = timeline_h / AP_MAX
	ready_actor = HashSet.new()

func _physics_process(delta: float) -> void:
	# 统计存活角色数量，去除死亡角色的头像等数据
	var live_actor_cnt := 0
	for a in Game.g_combat.get_actors():
		if a.is_alive():
			live_actor_cnt += 1
		elif texture_map.has(a):
			_on_actor_die(a)
	# 检查 ready 的角色，去掉 AP 低于 AP_THRESHOLD 的
	for a in ready_queue:
		if a.get_AP() < AP_THRESHOLD:
			ready_queue.erase(a)
			ready_actor.erase(a)
	var ready_size := ready_queue.size()
	# 执行行动条增长逻辑
	var must_do_turn := true if ready_size == live_actor_cnt else false
	if running and not btn_moving and not must_do_turn:
		if arrow_anmi.visible:
			arrow_anmi.lost_focus()
		add_all_actor_ap_and_btn_y(delta)
	# 设置角色头像位置
	set_all_actor_btn_pos()
	# ready 角色数量有增加，则暂停行动条，进入回合
	if ready_queue.size() > ready_size or (running and not btn_moving and must_do_turn):
		running = false
		var cur_actor = ready_queue.front()
		_set_actor_arrow_on_timeline(cur_actor)
		actor_ready.emit(cur_actor)

func _on_actor_die(a: ActorController) -> void:
	ready_queue.erase(a)
	if ready_actor.has(a):
		ready_actor.erase(a)
	if gain_ap_map.has(a):
		gain_ap_map.erase(a)
	if texture_map.has(a):
		texture_map.erase(a)

func start() -> void:
	for a in Game.g_combat.get_actors():
		a.AP._value = 0 # 这样赋值可以不触发事件
		var btn = packed_sprite.instantiate() as TextureButton
		btn.position.x = btn_origin_x
		btn.position.y = btn_origin_y
		btn.texture_normal = Game.g_actors.get_timeline_icon_by_actor_name(a.my_name)
		add_child(btn)
		gain_ap_map[a] = 0.0
		texture_map[a] = btn
	ready_queue.clear()
	ready_actor.clear()
	arrow_anmi = packed_arrow.instantiate() as AnimatedSprite2D
	add_child(arrow_anmi)
	running = true

func resume() -> void:
	running = true

# 增加角色 AP，设置 tmp_timeline_y（头像高度）
func add_all_actor_ap_and_btn_y(delta: float) -> void:
	for a in Game.g_combat.get_actors():
		if not a.is_alive():
			continue
		if a.get_AP() >= AP_MAX:
			var tmp_y = texture_map[a].position.y
			a.tmp_timeline_y = tmp_y
		else:
			var gain = a.get_ap_gain_per_sec() * delta
			gain_ap_map[a] += gain
			if gain_ap_map[a] >= 1.0:
				gain_ap_map[a] -= 1.0
				a.add_AP(1)
			var tmp_y = btn_origin_y - (a.get_AP() + gain_ap_map[a]) * len_per_ap
			a.tmp_timeline_y = tmp_y
		if not ready_actor.has(a) and a.get_AP() >= AP_THRESHOLD:
			ready_actor.append(a)
			ready_queue.push_back(a)

# 设置角色头像的位置（根据 tmp_timeline_y 等信息）
func set_all_actor_btn_pos() -> void:
	# 构建 spd 数组
	var spd := OrderedArray.new(_sort_actor_by_ap_gain_speed) # 有序数组，将角色按照速度从小到大排序，速度一样时，y坐标小（位置高）的在前面
	for a in Game.g_combat.get_actors():
		if a.is_alive():
			spd.append(a)
	# print("排序结果：", spd.get_data())
	# 构建角色的 spd 索引
	var actors: Dictionary[ActorController, int]
	var spd_arr = spd.get_data()
	for i in range(spd_arr.size()):
		actors[spd_arr[i]] = i
	# 设置头像按钮的绘制顺序
	for a in actors:
		texture_map[a].z_index = actors[a]
	# 首先为每个头像建立临时的重叠集
	var tmp : Dictionary[ActorController, Dictionary]  # value: {与 key 角色的间距小于 btn_spacing 且速度慢于 actor 的角色 a, 角色 a 对应的跳跃高度}
	for cur_a in actors:
		var cur_dict = {}
		var cur_y := cur_a.tmp_timeline_y
		var cur_spd_id = actors[cur_a]
		# print(cur_a.my_name, "(", cur_a.get_instance_id(), ") 排序位：", cur_spd_id, " -- 开始构建重叠集")
		for a in actors:
			if a == cur_a:
				continue
			if actors[a] > cur_spd_id:
				continue
			var dy = abs(cur_y - a.tmp_timeline_y)
			if dy < btn_spacing:
				cur_dict[a] = 33 * cos(btn_jump_arg * dy) + 32
		if cur_dict.size() > 0:
			tmp[cur_a] = cur_dict
			# print("构建完毕：", cur_dict)
		# else:
		# 	print("没有重叠，不用构建")
	# 设置各个角色的头像坐标
	for cur_a in actors:
		var new_x := btn_origin_x
		var new_y = cur_a.tmp_timeline_y
		if tmp.has(cur_a):
			for a in tmp[cur_a]:
				new_x += tmp[cur_a][a]
		texture_map[cur_a].position.y = new_y
		texture_map[cur_a].position.x = new_x

func update_actor_btn_pos(a: ActorController, gradually: bool = false) -> void:
	var new_y = btn_origin_y - (a.get_AP() + gain_ap_map[a]) * len_per_ap
	if not gradually:
		a.tmp_timeline_y = new_y
	else:
		btn_moving = true
		var current_p = texture_map[a].position
		var time = absf(new_y - current_p.y) * 3 / timeline_h
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(a, ^"tmp_timeline_y", new_y, time)
		tween.finished.connect(func():
			btn_moving = false
		)

func _sort_actor_by_ap_gain_speed(a1: ActorController, a2: ActorController) -> bool:
	var s1 := a1.get_ap_gain_per_sec()
	var s2 := a2.get_ap_gain_per_sec()
	if not is_equal_approx(s1, s2):
		return s1 < s2
	# 如果AP获得速度差不多，则根据名字排序
	var h1 := a1.my_name.hash()
	var h2 := a2.my_name.hash()
	if h1 != h2:
		return h1 < h2
	# 名字也一样，根据 obj id
	return a1.get_instance_id() < a2.get_instance_id()

# 设置箭头，指示当前回合属于哪个角色
func _set_actor_arrow_on_timeline(a: ActorController) -> void:
	if texture_map.has(a):
		arrow_anmi.get_parent().remove_child(arrow_anmi)
		texture_map[a].add_child(arrow_anmi)
		arrow_anmi.on_focus()
