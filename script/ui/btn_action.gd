extends Button

@export var action : GDScript

func _on_pressed():
	Game.g_event.send_event("event_chose_action", action.new())
