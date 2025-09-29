extends Node

@onready var ui: StoryUI = %StoryUI

var runner : StoryRunner

func _ready():
	runner = StoryRunner.new()
	runner.choice_requested.connect(_show_choices)
	runner.game_ended.connect(_show_ending)
	runner.start(load("res://addons/story_editor/demo/story_test.tres"))

func _show_choices(node: ChoiceNode, opts: PackedStringArray):
	ui.show_choices(opts, func(i: int):
		runner.choose(node.choices[i])
	)

func _show_ending(eid: String):
	ui.show_line("结局", "结束：%s" % eid)
	print("StoryRunner: 游戏结束 - %s" % eid)
	get_tree().create_timer(2.0).timeout.connect(func():
		get_tree().quit()
	)
