class_name PseudoRandom

# 伪随机数生成器，用于战斗回放的可复现性
# 使用线性同余生成器 (LCG) 算法 + 洗牌表算法减少极端值连击

static var _seed: int = 0
static var _current: int = 0

# 洗牌表参数
static var _shuffle_table: Array = []
static var _shuffle_index: int = 0
static var _table_size: int = 256  # 洗牌表大小

## 设置随机种子
## @param seed: 种子值
static func set_seed(the_seed: int) -> void:
	_seed = the_seed
	_current = the_seed
	_init_shuffle_table()

## 获取当前种子
static func get_seed() -> int:
	return _seed

## 重置到初始种子状态
static func reset() -> void:
	_current = _seed
	_init_shuffle_table()

## 初始化洗牌表
static func _init_shuffle_table() -> void:
	_shuffle_table.clear()
	_shuffle_index = 0
	
	# 先用LCG填充表
	for i in range(_table_size):
		_current = (_current * 1664525 + 1013904223) & 0x7FFFFFFF
		_shuffle_table.append(float(_current) / float(0x7FFFFFFF))
	
	# Fisher-Yates洗牌算法
	for i in range(_table_size - 1, 0, -1):
		_current = (_current * 1664525 + 1013904223) & 0x7FFFFFFF
		var j = _current % (i + 1)
		# 交换元素
		var temp = _shuffle_table[i]
		_shuffle_table[i] = _shuffle_table[j]
		_shuffle_table[j] = temp

## 生成下一个随机数 [0, 1)
static func randf() -> float:
	# 从洗牌表中获取随机数
	var result = _shuffle_table[_shuffle_index]
	
	# 更新索引
	_shuffle_index = (_shuffle_index + 1) % _table_size
	
	# 当用完表中一半的值时，重新洗牌部分表以保持随机性
	if _shuffle_index == 0:
		_reshuffle_table()
		
	return result
	
## 重新洗牌表，保持随机性但避免重复模式
static func _reshuffle_table() -> void:
	# 使用LCG更新当前状态
	_current = (_current * 1664525 + 1013904223) & 0x7FFFFFFF
	
	# 只对表的一部分进行洗牌，保留一些值以减少模式重复
	var shuffle_start := int(_table_size * 0.25)
	var shuffle_end := int(_table_size * 0.75)
	
	# 对表的中间部分进行Fisher-Yates洗牌
	for i in range(shuffle_end - 1, shuffle_start, -1):
		_current = (_current * 1664525 + 1013904223) & 0x7FFFFFFF
		var j = shuffle_start + (_current % (i - shuffle_start + 1))
		# 交换元素
		var temp = _shuffle_table[i]
		_shuffle_table[i] = _shuffle_table[j]
		_shuffle_table[j] = temp

## 生成指定范围的随机整数 [min_val, max_val]
static func randi_range(min_val: int, max_val: int) -> int:
	if min_val > max_val:
		push_error("PseudoRandom: min_val cannot be greater than max_val")
		return min_val
	
	var range_size = max_val - min_val + 1
	return min_val + int(randf() * range_size)

## 生成指定范围的随机浮点数 [min_val, max_val)
static func randf_range(min_val: float, max_val: float) -> float:
	if min_val > max_val:
		push_error("PseudoRandom: min_val cannot be greater than max_val")
		return min_val
	
	return min_val + randf() * (max_val - min_val)

## 根据概率返回布尔值
## @param probability: 概率值 [0.0, 1.0]
static func chance(probability: float) -> bool:
	return randf() < probability