class_name TimelineController extends TextureProgressBar

const AP_THRESHOLD := 5
const AP_MAX := 10
const btn_origin_x := 11.5  # 头像初始横坐标
const btn_origin_y := 568.0 # 头像初始纵坐标 = size.y - 32
const btn_spacing  := 69.5  # 头像开始“跳跃”时纵向间距dy的最大值（跳跃高度 = btn_jump_h*cos(btn_jump_arg*dy)+btn_jump_h）
const btn_jump_arg := 0.045
const timeline_h := 590.0   # 行动条高度 = size.y - 10

@export var packed_sprite : PackedScene
@export var packed_greenbox : PackedScene

var running     : bool
var btn_moving  : bool
var btn_jump_h  : float
var len_per_ap  : float
var select_box  : AnimatedSprite2D
var current_turn_btn : TextureButton
var mouse_enterd_btn : TextureButton
var tween_move  : Tween
var ready_actors : HashSet
var ready_queue : Array[ActorController] = []
var gain_ap_map : Dictionary[ActorController, float]
var texture_map : Dictionary[ActorController, TextureButton]

func _init() -> void:
	running = false
	btn_moving = false
	max_value = AP_MAX
	value = AP_THRESHOLD
	btn_jump_h = 18.0
	len_per_ap = timeline_h / AP_MAX
	ready_actors = HashSet.new()
	current_turn_btn = null
	mouse_enterd_btn = null

func _physics_process(delta: float) -> void:
	# 统计存活角色数量，去除死亡角色的头像等数据
	var live_actor_cnt := 0
	for a in Game.g_combat.get_actors():
		if a.is_alive():
			live_actor_cnt += 1
		elif texture_map.has(a):
			_on_actor_die(a)
	# 检查 ready 的角色，去掉 AP 低于 AP_THRESHOLD 的
	var actor_max_ap_cnt := 0
	for a in ready_actors.to_array():
		if a.get_AP() < AP_THRESHOLD:
			ready_actors.erase(a)
		elif a.get_AP() >= AP_MAX:
			actor_max_ap_cnt += 1
	var must_do_turn := true if actor_max_ap_cnt == live_actor_cnt else false
	# 执行行动条增长逻辑
	ready_queue.clear()
	if running and not btn_moving and not must_do_turn and ready_queue.size() == 0:
		if select_box.visible:
			select_box.stop()
			select_box.hide()
		add_all_actor_ap_and_btn_y(delta)
	# 设置角色头像位置
	_set_btn_jump_hgiht_by_actor_cnt(live_actor_cnt, delta)
	set_all_actor_btn_pos()
	# ready 角色数量有增加，则暂停行动条，进入回合
	if ready_queue.size() > 0 or (running and not btn_moving and must_do_turn):
		running = false
		var cur_actor = ready_queue.front()
		set_actor_actived_on_timeline(cur_actor)
		Game.g_combat.turn_started(cur_actor)

func clear_on_change_scene() -> void:
	ready_actors.clear()
	ready_queue.clear()
	gain_ap_map.clear()
	for a in texture_map:
		texture_map[a].queue_free()
	texture_map.clear()

func _on_actor_die(a: ActorController) -> void:
	ready_queue.erase(a)
	ready_actors.erase(a)
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
		btn.mouse_entered.connect(on_mouse_enter_btn.bind(btn))
		btn.mouse_exited.connect(on_mouse_exit_btn.bind(btn))
		btn.set_actor(a)
		add_child(btn)
		gain_ap_map[a] = 0.0
		texture_map[a] = btn
	ready_actors.clear()
	select_box = packed_greenbox.instantiate() as AnimatedSprite2D
	current_turn_btn = null
	mouse_enterd_btn = null
	running = true

func resume_timeline() -> void:
	print("resume_timeline")
	running = true

func on_mouse_enter_btn(btn: TextureButton) -> void:
	mouse_enterd_btn = btn # 绘制层级设为最高
	for a in texture_map:
		if texture_map[a] == btn:
			Game.g_combat.scene.select_preview_actor(a)
			return

func on_mouse_exit_btn(btn: TextureButton) -> void:
	if btn == mouse_enterd_btn:
		mouse_enterd_btn = null
		for a in texture_map:
			if texture_map[a] == btn:
				Game.g_combat.scene.release_preview_actor(a)
				return

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
		if a.get_AP() >= AP_THRESHOLD:
			ready_queue.push_back(a)
			if not ready_actors.has(a):
				ready_actors.append(a)

# 动态调整角色头像重叠时“跳起”的高度
func _set_btn_jump_hgiht_by_actor_cnt(live_actor_cnt: int, delta: float) -> void:
	var target_jump_high := 32.0
	# if Game.Debug == 1: # 测试时看最紧凑的效果如何
	# 	target_jump_high = 18.0
	if live_actor_cnt >= 15:
		target_jump_high = 18.0
	elif live_actor_cnt > 5:
		target_jump_high = 39 - 1.4 * live_actor_cnt # (5,32)->(15,18)
	if not is_equal_approx(target_jump_high, btn_jump_h):
		var dh := delta * 6 # 6像素/秒
		if absf(target_jump_high - btn_jump_h) > dh:
			if target_jump_high < btn_jump_h:
				btn_jump_h -= dh
			else:
				btn_jump_h += dh
		else:
			btn_jump_h = target_jump_high

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
		if mouse_enterd_btn and texture_map[a] == mouse_enterd_btn:
			mouse_enterd_btn.z_index = 1000
		elif current_turn_btn and texture_map[a] == current_turn_btn:
			current_turn_btn.z_index = 990
		else:
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
				cur_dict[a] = (cos(btn_jump_arg * dy) + 1) * btn_jump_h
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
		tween_move = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_move.tween_property(a, ^"tmp_timeline_y", new_y, time)
		tween_move.finished.connect(func():
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

# 设置UI，指示当前回合属于哪个角色
func set_actor_actived_on_timeline(a: ActorController) -> void:
	if texture_map.has(a):
		if select_box.get_parent():
			select_box.get_parent().remove_child(select_box)
		texture_map[a].add_child(select_box)
		select_box.show()
		select_box.play(&"default")
		current_turn_btn = texture_map[a]
