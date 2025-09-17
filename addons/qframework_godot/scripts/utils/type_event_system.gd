## 事件总线

class_name TypeEventSystem extends RefCounted

## 推送事件
func send_event(destination: String, payload = null) -> void:
	if payload == null:
		payload = []
	if not payload is Array:
		payload = [payload]
	else: # payload is Arrray
		var new_payload = []
		new_payload.append(payload)
		payload = new_payload
	payload.insert(0, _get_destination_signal(destination))
	var ret = callv("emit_signal", payload)
	print("send_event: ", payload[0], " res: ", ret)

## 订阅
func register_event(destination: String, callback: Callable) -> void:
	var dest_signal: String = _get_destination_signal(destination)
	if not is_connected(dest_signal, callback):
		connect(dest_signal, callback)
	
## 取消订阅
func unregister_event(destination: String, callback: Callable) -> void:
	var dest_signal: String = _get_destination_signal(destination)
	if is_connected(dest_signal, callback):
		disconnect(dest_signal, callback)

## 获取事件名		
func _get_destination_signal(destination: String) -> String:
	var dest_signal: String = "EventBus|%s" % destination
	if not has_user_signal(dest_signal):
		add_user_signal(dest_signal)
	return dest_signal
