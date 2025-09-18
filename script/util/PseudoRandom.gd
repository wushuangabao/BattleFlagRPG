class_name PseudoRandom

# 伪随机数生成器，用于战斗回放的可复现性
# 使用线性同余生成器 (LCG) 算法

static var _seed: int = 0
static var _current: int = 0

## 设置随机种子
## @param seed: 种子值
static func set_seed(the_seed: int) -> void:
	_seed = the_seed
	_current = the_seed

## 获取当前种子
static func get_seed() -> int:
	return _seed

## 重置到初始种子状态
static func reset() -> void:
	_current = _seed

## 生成下一个随机数 [0, 1)
static func randf() -> float:
	# 使用标准的LCG参数 (来自Numerical Recipes)
	_current = (_current * 1664525 + 1013904223) & 0x7FFFFFFF
	return float(_current) / float(0x7FFFFFFF)

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