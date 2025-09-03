class_name AttributeBase

signal maximum_changed(maximum)
signal value_changed(value)

var maximum := 0 :
	set(v):
		if maximum != v:
			_set_maximum(v)
var value := 0 :
	set(v):
		if value != v:
			_set_value(v)

func fill()-> void:
	_set_value(maximum)

func empty() -> void:
	_set_value(0)

func get_difference() -> int:
	return maximum - value

func has_half() -> bool:
	return value * 2 >= maximum

func is_full() -> bool:
	return value == maximum

func is_empty() -> bool:
	return value == 0

func _set_maximum(new_maximum: int) -> void:
	maximum = new_maximum
	emit_signal("maximum_changed", maximum)

func _set_value(new_value: int) -> void:
	value = clamp(new_value, 0, maximum)
	emit_signal("value_changed", value)
