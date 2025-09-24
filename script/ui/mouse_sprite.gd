extends Sprite2D

@export var texture_normal : Texture2D
@export var offset_fix := Vector2(-1, -1)

# 粒子特效
@export var particle_color := Color(0.99, 0.83, 0.19)
@export var particle_amount := 9
@export var particle_lifetime := 0.6
@export var particle_spread := 45.0
@export var particle_speed := 100.0

func _ready() -> void:
	if Game.Debug == 1:
		# Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	
	texture = texture_normal
	offset = offset_fix
	
	# 确保鼠标指针始终在最上层显示
	z_index = 999  # 设置较高的z_index值
	z_as_relative = false  # 使z_index为绝对值，不受父节点影响

func _process(_delta) -> void:
	global_position = get_global_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				create_click_particles()

# 创建鼠标点击粒子特效
func create_click_particles() -> void:
	# 创建粒子系统
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	
	# 设置粒子位置为当前鼠标位置
	particles.global_position = get_global_mouse_position()
	
	# 设置粒子系统参数
	particles.emitting = true
	particles.amount = particle_amount
	particles.lifetime = particle_lifetime
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.randomness = 0.5
	particles.direction = Vector2(0, -1)
	particles.spread = particle_spread
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = particle_speed * 0.7
	particles.initial_velocity_max = particle_speed
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 3.0
	particles.color = particle_color
	
	# 设置粒子层级
	particles.z_index = 998  # 确保在鼠标指针下方但仍然在高层级
	
	# 设置自动销毁
	var timer = Timer.new()
	particles.add_child(timer)
	timer.wait_time = particle_lifetime + 0.5  # 等待时间略长于粒子生命周期
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(func(): particles.queue_free())
