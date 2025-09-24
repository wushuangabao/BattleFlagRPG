extends Node

@onready var ui: StoryUI = %StoryUI

var runner : StoryRunner

func _ready():
	runner = StoryRunner.new()

	# 连接信号
	runner.choice_requested.connect(func(node: ChoiceNode, opts: PackedStringArray):
		ui.show_choices(opts, func(i: int):
			runner.choose(i)
		)
	)
	runner.game_ended.connect(func(eid: String):
		ui.show_line("结局", "结束：%s" % eid)
		print("StoryRunner: 游戏结束 - %s" % eid)
		get_tree().create_timer(2.0).timeout.connect(func():
			get_tree().quit()
		)
	)

	runner.start(load("res://addons/story_editor/demo/story_test.tres"))
