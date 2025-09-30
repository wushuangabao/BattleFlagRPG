class_name StoryGraphManager

# 简单的会话管理器：用于在同一 StoryRunner 中管理多个 StoryGraph
# 会话结构：
# {
#   "id": String,
#   "graph": StoryGraph,
#   "current": StoryNode,
#   "state": { "variables": {}, "visited": {} }
# }

var _sessions: Dictionary[String, Dictionary] = {}

func create_session(graph: StoryGraph, entry: String = "") -> String:
    var sid := _gen_session_id(graph)
    if _sessions.has(sid):
        push_warning("StoryGraphManager: session already exists: %s" % sid)
    graph.id = sid
    var session := {
        "graph": graph,
        "current": null,
        "state": {"variables": {}, "visited": {}}
    }
    _sessions[sid] = session
    graph.ensure_entry()
    if graph.entry_node and graph.entry_node != "":
        var entry_node = graph.get_node_by_id(graph.entry_node)
        if entry_node != null:
            session["current"] = entry_node
        else:
            push_warning("StoryGraphManager create_session: %s 没有找到入口节点 %s" % [graph.title, graph.entry_node])
    else:
        push_warning("StoryGraphManager create_session: %s 没有设置入口节点" % graph.title)
    return sid

func has_session(id: String) -> bool:
    return _sessions.has(id)

func remove_session(id: String) -> void:
    if _sessions.has(id):
        _sessions.erase(id)

func get_session(id: String) -> Dictionary:
    return _sessions.get(id, {})

func get_graph(id: String) -> StoryGraph:
    var s := get_session(id)
    return s.get("graph", null)

func get_current(id: String) -> StoryNode:
    var s := get_session(id)
    return s.get("current", null)

func set_current(id: String, node: StoryNode) -> void:
    var s := get_session(id)
    if s.is_empty():
        return
    s["current"] = node

func get_state(id: String) -> Dictionary:
    var s := get_session(id)
    return s.get("state", {"variables": {}, "visited": {}})

func mark_visited(id: String, node_id: String) -> void:
    var st := get_state(id)
    st["visited"][node_id] = true

func _gen_session_id(graph: StoryGraph) -> String:
    var base := graph.id if graph.id != "" else "graph"
    var sid := "%s_%s" % [base, str(Time.get_ticks_msec())]
    var idx := 0
    while _sessions.has(sid):
        idx += 1
        sid = "%s_%s_%d" % [base, str(Time.get_ticks_msec()), idx]
    return sid

func get_valid_graphs() -> Array[Dictionary]:
    var valid_graphs: Array[Dictionary] = []
    for s in _sessions.values():
        if s.has("current") and s["current"] != null and (s["current"] is ChoiceNode):
            valid_graphs.append(s)
    return valid_graphs