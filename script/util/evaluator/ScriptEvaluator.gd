class_name ScriptEvaluator extends Evaluator

## 允许使用自定义GDScript代码进行条件判断的Evaluator
## 可以通过script_code属性设置自定义脚本代码
## 脚本代码必须返回一个布尔值

@export var my_script: GDScript

# 用于存储编译后的脚本对象
var _script_instance = null

var _has_error: bool = false
var _error_message: String = ""

## 编译脚本代码
func _compile_script() -> void:
	_has_error = false
	_error_message = ""
	
	# 创建脚本实例
	_script_instance = my_script.new()
	if not _script_instance:
		_has_error = true
		_error_message = "无法创建脚本实例"

## 评估条件
func evaluate(state: Dictionary) -> bool:
	if not _script_instance:
		_compile_script()

	if _has_error or not _script_instance:
		push_warning("ScriptEvaluator错误: " + _error_message)
		return false
	
	# 调用脚本实例的evaluate方法
	var result = false
	
	# 调用脚本实例的evaluate方法
	# GDScript没有try-catch语法，使用安全调用方式
	if _script_instance.has_method("evaluate"):
		result = _script_instance.call("evaluate", state)
		if result == null:
			push_warning("ScriptEvaluator运行时错误: 返回值为null")
			return false
	else:
		push_warning("ScriptEvaluator错误: 脚本实例没有evaluate方法")
		return false
	
	# 确保结果是布尔值
	if not (result is bool):
		push_warning("ScriptEvaluator错误: 脚本必须返回布尔值，而不是 " + str(typeof(result)))
		return false
	
	return result

## 获取错误信息
func get_error() -> String:
	return _error_message

## 检查是否有错误
func has_error() -> bool:
	return _has_error
