class_name IOCContainer extends RefCounted

var m_instances :Dictionary = {}

func register(v):
	var key = v.get_global_name() if v is GDScript else &""
	var instance
	if !key.is_empty(): # 此时 v 是一个类型名，将其实例化
		instance = v.new()
	else:
		var scr = v.get_script()
		if scr is Script:
			key = scr.get_global_name()
			instance = v
		else:
			push_error("IOCContainer 注册失败：参数错误！")
			return null
	m_instances[key] = instance
	return instance

func get_value(v):
	var key = v.get_global_name() if v is GDScript else &""
	if key.is_empty():
		var scr = v.get_script()
		if scr is Script:
			key = scr.get_global_name() as StringName
		else:
			push_error("IOCContainer 获取失败：参数错误！")
			return null
	if m_instances.has(key):
		return m_instances.get(key)
	else:
		push_error("IOCContainer 获取失败：未注册 ", key)
		return null
