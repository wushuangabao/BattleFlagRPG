extends Node

@onready var ui: StoryUI = %StoryUI

var runner : StoryRunner
var session_id: String

func _ready():
	runner = StoryRunner.new()
	runner.choice_requested_for.connect(_show_choices)
	runner.game_ended_for.connect(_show_ending)
	session_id = runner.start(load("res://addons/story_editor/demo/story_test.tres"))

func _show_choices(sid: String, node: ChoiceNode, opts: PackedStringArray):
	ui.show_choices(opts, func(i: int):
		runner.choose_for(sid, node.choices[i])
	)

func _show_ending(sid: String, eid: String):
	ui.show_line("结局", "结束：%s" % eid)
	print("StoryRunner: 游戏结束 - %s" % eid)
	get_tree().create_timer(2.0).timeout.connect(func():
		get_tree().quit()
	)
