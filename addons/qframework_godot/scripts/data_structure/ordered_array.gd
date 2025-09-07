class_name OrderedArray

var _data : Array = []
var _order_func : Callable

func _init(f: Callable):
	_order_func = f

# 添加元素（维持数组有序）
func append(value, sort_func = null) -> void:
	# 如果数组为空，直接添加
	if _data.is_empty():
		_data.append(value)
		return
	# 插入位置使用二分查找
	var left = 0
	var right = _data.size() - 1
	var insert_index = 0
	while left <= right:
		var mid = (left + right) / 2
		var mid_val = _data[mid]
		var ret = false
		if _order_func.call(value, mid_val):
			right = mid - 1
			insert_index = mid
		else:
			left = mid + 1
			insert_index = left
	_data.insert(insert_index, value)

func erase(value) -> void:
	_data.erase(value)

func has(value) -> bool:
	return _data.has(value)

func size() -> int:
	return _data.size()

func is_empty() -> bool:
	return _data.is_empty()

func clear() -> void:
	_data.clear()

func merge(values: Array) -> void:
	for v in values:
		append(v)

func get_data() -> Array:
	return _data
