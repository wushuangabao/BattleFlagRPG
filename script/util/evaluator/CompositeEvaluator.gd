class_name CompositeEvaluator extends Evaluator

## 组合多个Evaluator进行逻辑操作的评估器
## 支持AND、OR、NOT等逻辑操作

enum LogicType {
	AND,  # 所有条件都为真时返回真
	OR,   # 任一条件为真时返回真
	NOT,  # 对单个条件取反
	XOR,  # 有且仅有一个条件为真时返回真
	NAND, # 非与（NOT AND）
	NOR   # 非或（NOT OR）
}

@export var logic_type: LogicType = LogicType.AND
@export var evaluators: Array[Evaluator] = []

## 评估组合条件
func evaluate(state: Dictionary) -> bool:
	# 如果没有条件，默认返回true
	if evaluators.is_empty():
		return true
	
	# 对于NOT操作，只考虑第一个条件
	if logic_type == LogicType.NOT:
		if evaluators.size() >= 1:
			return not evaluators[0].evaluate(state)
		return true
	
	# 处理其他逻辑类型
	match logic_type:
		LogicType.AND:
			# 所有条件都为真时返回真
			for evaluator in evaluators:
				if not evaluator.evaluate(state):
					return false
			return true
			
		LogicType.OR:
			# 任一条件为真时返回真
			for evaluator in evaluators:
				if evaluator.evaluate(state):
					return true
			return false
			
		LogicType.XOR:
			# 有且仅有一个条件为真时返回真
			var true_count = 0
			for evaluator in evaluators:
				if evaluator.evaluate(state):
					true_count += 1
			return true_count == 1
			
		LogicType.NAND:
			# 非与（NOT AND）
			for evaluator in evaluators:
				if not evaluator.evaluate(state):
					return true
			return false
			
		LogicType.NOR:
			# 非或（NOT OR）
			for evaluator in evaluators:
				if evaluator.evaluate(state):
					return false
			return true
			
	# 默认情况
	return false

## 添加一个评估器到列表中
func add_evaluator(evaluator: Evaluator) -> void:
	if evaluator:
		evaluators.append(evaluator)

## 移除一个评估器
func remove_evaluator(evaluator: Evaluator) -> bool:
	var index = evaluators.find(evaluator)
	if index != -1:
		evaluators.remove_at(index)
		return true
	return false

## 清空所有评估器
func clear_evaluators() -> void:
	evaluators.clear()
