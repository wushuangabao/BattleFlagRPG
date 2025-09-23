class_name ChoiceEffect extends Resource

# 最小实现：只改变量字典，或发信号
@export var key: String = ""
@export var op: String = "set" # set/add/toggle
@export var value: int

func apply(state: Dictionary) -> void:
	# state.variables: Dictionary
	if not state.has("variables"):
		state.variables = {}
	match op:
		"set":
			state.variables[key] = value
		"add":
			var old = state.variables.get(key, 0)
			state.variables[key] = old + (value if value is int else 0)
		"toggle":
			state.variables[key] = not bool(state.variables.get(key, false))
		_:
			state.variables[key] = value
