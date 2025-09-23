extends Node

@onready var ui: StoryUI = %StoryUI

var runner : StoryRunner

func _ready():
	runner = StoryRunner.new()

	# 连接信号
	runner.choice_requested.connect(func(node:Resource, opts:PackedStringArray):
		ui.show_choices(opts, func(i:int):
			runner.choose(i)
		)
	)
	runner.ended.connect(func(eid:String):
		ui.show_line("结局", "结束：%s" % eid)
	)
	# 构建一个最小剧情图（也可以从资源加载 .tres）
	var graph := load("res://addons/story_editor/demo/story_test.tres")
	runner.start(graph)
