class_name MathUtils

# Vector2i的点乘方法
static func vector2i_dot(a: Vector2i, b: Vector2i) -> int:
	return a.x * b.x + a.y * b.y

# Vector3i的点乘方法
static func vector3i_dot(a: Vector3i, b: Vector3i) -> int:
	return a.x * b.x + a.y * b.y + a.z * b.z

# 计算两个向量之间的夹角（弧度）
static func angle_between(a, b) -> float:
	# 处理Vector2i类型
	if a is Vector2i and b is Vector2i:
		var a_float = Vector2(a.x, a.y)
		var b_float = Vector2(b.x, b.y)
		return a_float.angle_to(b_float)
	
	# 处理Vector3i类型
	elif a is Vector3i and b is Vector3i:
		var a_float = Vector3(a.x, a.y, a.z)
		var b_float = Vector3(b.x, b.y, b.z)
		return a_float.angle_to(b_float)
	
	# 处理Vector2类型
	elif a is Vector2 and b is Vector2:
		return a.angle_to(b)
	
	# 处理Vector3类型
	elif a is Vector3 and b is Vector3:
		return a.angle_to(b)
	
	# 如果类型不匹配，返回0
	return 0.0

# 计算两个向量之间夹角的余弦值
static func cos_angle_between(a, b) -> float:
	var dot_product = 0.0
	var magnitude_a = 0.0
	var magnitude_b = 0.0
	
	# 处理Vector2i类型
	if a is Vector2i and b is Vector2i:
		dot_product = vector2i_dot(a, b)
		magnitude_a = sqrt(vector2i_dot(a, a))
		magnitude_b = sqrt(vector2i_dot(b, b))
	
	# 处理Vector3i类型
	elif a is Vector3i and b is Vector3i:
		dot_product = vector3i_dot(a, b)
		magnitude_a = sqrt(vector3i_dot(a, a))
		magnitude_b = sqrt(vector3i_dot(b, b))
	
	# 处理Vector2类型
	elif a is Vector2 and b is Vector2:
		dot_product = a.dot(b)
		magnitude_a = a.length()
		magnitude_b = b.length()
	
	# 处理Vector3类型
	elif a is Vector3 and b is Vector3:
		dot_product = a.dot(b)
		magnitude_a = a.length()
		magnitude_b = b.length()
	
	# 避免除以0
	if magnitude_a == 0 or magnitude_b == 0:
		return 0.0
		
	return dot_product / (magnitude_a * magnitude_b)