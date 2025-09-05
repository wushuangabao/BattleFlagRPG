class_name ActionMove extends ActionBase

var path: PackedVector2Array
func _init(p : Vector2i) -> void:
	cost = {
		&"AP" : 5
	}

func execute() -> void:
	pass
