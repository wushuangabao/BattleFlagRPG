class_name AttributeBase extends Resource

signal maximum_changed(actor, new_maximum)
signal value_changed(actor, new_value)

var _maximum : int
var _value : int
var _actor : ActorController

var value:
	get:
		return _value
	set(new_value):
		if _value != new_value:  # 只有值真正改变时才发射信号
			value_changed.emit(_actor, new_value, _value)
			_value = new_value

var maximum:
	get():
		return _maximum
	set(v):
		if _maximum != v:
			maximum_changed.emit(_actor, v, _maximum)
			_maximum = v

func set_maximum(new_maximum: int) -> void:
	maximum = new_maximum

func set_value(new_value: int) -> void:
	value = clamp(new_value, 0, _maximum) as int

func register(on_value_changed: Callable, on_maximum_changed = null):
	value_changed.connect(on_value_changed)
	if on_maximum_changed:
		maximum_changed.connect(on_maximum_changed)

func unregister(on_value_changed: Callable, on_maximum_changed = null):
	value_changed.disconnect(on_value_changed)
	if on_maximum_changed:
		maximum_changed.disconnect(on_maximum_changed)

func _init(a: ActorController, default_value: int = 10, default_maximum: int = 10) -> void:
	_maximum = default_maximum if default_maximum > 0 else 1
	_value = clamp(default_value, 0, _maximum)
	_actor = a

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
