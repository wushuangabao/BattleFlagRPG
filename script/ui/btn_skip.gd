extends Button

func _on_pressed():
	Game.g_event.send_event("event_chose_action", ActionSkipTurn.new())
