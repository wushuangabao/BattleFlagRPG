class_name TimelineController extends AbstractSystem

const AP_THRESHOLD := 100.0
const AP_MAX := 200.0

signal actor_ready

var running    : bool = false
var ready_queue: Array[ActorController] = []

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
		var gain = int(a.get_ap_gain_per_sec() * delta) as int
		if gain > AP_MAX:
			gain = AP_MAX
		a.add_AP(gain)
		if a.ap >= AP_THRESHOLD:
			ready_queue.append(a)
			any_ready = true
	if any_ready and ready_queue.size() > 0:
		running = false
		emit_signal("actor_ready", ready_queue.pop_front())

func start(actors_list: Array[ActorController]) -> void:
	for a in Game.g_combat.get_actors():
		a.ap = 0.0
	ready_queue.clear()
	running = true

func resume() -> void:
	running = true
