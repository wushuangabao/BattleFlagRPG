class_name SkillAreaShape extends Resource

enum ShapeType {
	Single, Line, Ring, Custom
}
@export var custom_id  := -1 # range_select表中的id。如果不是-1，就由配表来控制范围
@export var shape_type := ShapeType.Single
@export var d_inner    := 0  # 近端点的距离
@export var d_outer    := 0  # 远端点的距离
@export var target_range := 0      # 范围大小（对Single是目标为圆心的范围半径，对Ring是角度大小1/2/4）
@export var is_blockable := false  # 可被阻挡（针对单格或直线）
var area_params = { # 长度、角度、是否穿透、最大目标数
	
}
