extends Node

@onready var ui: StoryUI = %StoryUI

var runner : StoryRunner
var session_id: String

func _ready():
	runner = StoryRunner.new()
	runner.choice_requested_for.connect(_show_choices)
	Game.g_event.register_event("story_ended", _show_ending)
	session_id = runner.start(load("res://addons/story_editor/demo/story_test.tres"))

func _show_choices(sid: String, node: ChoiceNode, opts: PackedStringArray):
	ui.show_choices(opts, func(i: int):
		runner.choose_for(sid, node.choices[i])
	)

func _show_ending(params: Array):
	var sid = params[0]
	var eid = params[1]
	ui.show_line("结局", "结束：%s" % eid)
	print("StoryRunner: 游戏结束 - %s" % eid)
	get_tree().create_timer(2.0).timeout.connect(func():
		get_tree().quit()
	)
