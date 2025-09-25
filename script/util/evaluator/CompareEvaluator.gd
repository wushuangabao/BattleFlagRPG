class_name CompareEvaluator extends Evaluator

@export var key: String = ""
@export var cmp: String = "exists" # exists, =, !=, >, >=, <, <=
@export var value: int

func evaluate(state: Dictionary) -> bool:
	var vars = state.get("variables", {})
	match cmp:
		"exists":
			return vars.has(key)
		"=":
			return vars.get(key) == value
		"!=":
			return vars.get(key) != value
		">":
			return float(vars.get(key, 0)) > float(value)
		">=":
			return float(vars.get(key, 0)) >= float(value)
		"<":
			return float(vars.get(key, 0)) < float(value)
		"<=":
			return float(vars.get(key, 0)) <= float(value)
		_:
			return false
