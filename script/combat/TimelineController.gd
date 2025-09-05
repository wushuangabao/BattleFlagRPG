class_name TimelineController extends AbstractSystem

const AP_THRESHOLD := 10
const AP_MAX := 20

signal actor_ready

var running     : bool = false
var ready_queue : Array[ActorController] = []
var gain_ap_map : Dictionary[ActorController, float]

func _physics_process(delta: float) -> void:
	if not running:
		return
	if ready_queue.size() > 0:
		return
	var any_ready := false
	for a in Game.g_combat.get_actors():
		if not a.is_alive():
			continue
		if a.get_AP() >= AP_THRESHOLD:
			continue
		var gain = a.get_ap_gain_per_sec() * delta
		if gain_ap_map.has(a):
			gain_ap_map[a] += gain
		else:
			gain_ap_map[a] = gain
		if gain_ap_map[a] >= 1.0:
			gain_ap_map[a] -= 1.0
			a.add_AP(1)
		if a.get_AP() >= AP_THRESHOLD:
			ready_queue.append(a)
			any_ready = true
	if any_ready and ready_queue.size() > 0:
		running = false
		actor_ready.emit(ready_queue.pop_front())

func start(actors_list: Array[ActorController]) -> void:
	for a in Game.g_combat.get_actors():
		a.AP._value = 0 # 这样赋值可以不触发事件
	ready_queue.clear()
	running = true

func resume() -> void:
	running = true
