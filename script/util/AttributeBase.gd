class_name AttributeBase extends BindableProperty

signal maximum_changed(maximum)
var _maximum : int

var maximum:
	get():
		return _maximum
	set(v):
		if _maximum != v:
			_maximum = v
			maximum_changed.emit(_maximum)

func _init(default_value: int = 10, default_maximum: int = 10) -> void:
	_maximum = default_maximum if default_maximum > 0 else 1
	_value = clamp(default_value, 0, _maximum)

func fill()-> void:
	value = _maximum

func empty() -> void:
	value = 0

func get_difference() -> int:
	return maximum - value

func has_half() -> bool:
	return value * 2 >= maximum

func is_full() -> bool:
	return value == maximum

func is_empty() -> bool:
	return value == 0

func set_maximum(new_maximum: int) -> void:
	maximum = new_maximum

func set_value(new_value: int) -> void:
	value = clamp(new_value, 0, _maximum) as int
