class_name TimelineController extends ProgressBar

const AP_THRESHOLD := 7
const AP_MAX := 7

signal actor_ready # 通知到 BattleSystem._turn_controller.do_turn

@export var packed_sprite : PackedScene

var running     : bool
var len_per_ap  : float
var ready_queue : Array[ActorController] = []
var gain_ap_map : Dictionary[ActorController, float]
var sprite_map  : Dictionary[ActorController, Sprite2D]

func _ready() -> void:
	running = false
	max_value = AP_MAX
	value = AP_THRESHOLD
	len_per_ap = size.x / AP_MAX

func _physics_process(delta: float) -> void:
	if not running:
		return
	if ready_queue.size() > 0:
		running = false
		actor_ready.emit(ready_queue.pop_front())
		return
	var any_ready := false
	for a in Game.g_combat.get_actors():
		if not a.is_alive():
			continue
		if a.get_AP() >= AP_THRESHOLD:
			continue
		var gain = a.get_ap_gain_per_sec() * delta
		gain_ap_map[a] += gain
		set_actor_sprite_x(a)
		if gain_ap_map[a] >= 1.0:
			gain_ap_map[a] -= 1.0
			a.add_AP(1)
		if a.get_AP() >= AP_THRESHOLD:
			ready_queue.push_back(a)
			any_ready = true
	if any_ready and ready_queue.size() > 0:
		running = false
		actor_ready.emit(ready_queue.pop_front())

func start(actors_list: Array[ActorController]) -> void:
	for a in Game.g_combat.get_actors():
		a.AP._value = 0 # 这样赋值可以不触发事件
		#a.AP.register(func(new_ap):
			#print("Timeline 接收到AP变更信号：", new_ap, " - ", a.my_name)
		#)
		var new_sprite = packed_sprite.instantiate() as Sprite2D
		new_sprite.transform.origin.x = 0.0
		new_sprite.transform.origin.y = 75.0
		add_child(new_sprite)
		gain_ap_map[a] = 0.0
		sprite_map[a] = new_sprite
	ready_queue.clear()
	running = true

func resume() -> void:
	running = true

func set_actor_sprite_x(a: ActorController, gradually: bool = false) -> void:
	var new_x = (a.get_AP() + gain_ap_map[a]) * len_per_ap
	if gradually:
		var current_transform = sprite_map[a].transform
		var new_transform = current_transform
		new_transform.origin.x = new_x
		var time = absf(new_x - current_transform.origin.x) * 2 / size.x
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite_map[a], ^"transform", new_transform, time)
	else:
		sprite_map[a].transform.origin.x = new_x
