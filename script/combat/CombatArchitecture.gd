class_name CombatArchitecture extends Architecture

func _init(model: UnitStat) -> void:
	self.register_system(Game.g_actors)
	self.register_model(model)
	make_sure_architecture()
