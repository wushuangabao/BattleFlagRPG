class_name ActionBase

enum TargetType {
	Unit,
	Cell,
	None
}
var target  : TargetType
var cost := {
	"AP"    : 1,
	"MP"    : 0 
}

func validate(context):
	pass

func execute(context, on_step): # 可分帧播放
	pass

func prediction(context): # 供 UI 预览
	pass
