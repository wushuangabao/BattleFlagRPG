@tool
extends VBoxContainer

# 视口里的固定坐标：要把“边缘上的点”锁到这里
var lock_point: Vector2 = Vector2(1050, 600)

# 选择哪条边：0=Left, 1=Right, 2=Top, 3=Bottom
@export_enum("Left", "Right", "Top", "Bottom")
var edge: int = 0

# 该边上的插值参数（0~1）
# Left/Right 边：t=0 顶端，t=1 底端
# Top/Bottom 边：t=0 左端，t=1 右端
@export_range(0.0, 1.0, 0.001)
var t: float = 0.5

# 是否根据“被锁的边”自动设置扩展方向（推荐开）
@export var auto_grow_from_locked_edge: bool = true

func set_lock_point(p: Vector2) -> void:
	# 设置锁定点
	lock_point = p
	_align_to_lock_point()

func _ready() -> void:
	# 作为视口顶层控件来定位（不受父容器布局影响）
	top_level = true

	# 把控件的四个锚点都设置为 0，也就是把控件的锚点全部固定在父节点的左上角（绝对像素模式）
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.0
	anchor_bottom = 0.0

	if auto_grow_from_locked_edge:
		_apply_auto_grow()

	_align_to_lock_point()

	# 大小或视口变化时，重新对齐
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	if get_viewport() and not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	# 子项最小尺寸变动导致容器大小可能变化
	if not minimum_size_changed.is_connected(_on_minimum_size_changed):
		minimum_size_changed.connect(_on_minimum_size_changed)

func _apply_auto_grow() -> void:
	# 根据“被锁住的边”，把增长方向默认设成“远离该边”
	match edge:
		0: # Left 被锁 -> 横向向右扩
			grow_horizontal = Control.GROW_DIRECTION_END
			grow_vertical   = Control.GROW_DIRECTION_BOTH
		1: # Right 被锁 -> 横向向左扩
			grow_horizontal = Control.GROW_DIRECTION_BEGIN
			grow_vertical   = Control.GROW_DIRECTION_BOTH
		2: # Top 被锁 -> 竖向向下扩
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical   = Control.GROW_DIRECTION_END
		3: # Bottom 被锁 -> 竖向向上扩
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical   = Control.GROW_DIRECTION_BEGIN

func _align_to_lock_point() -> void:
	# 根据当前 size、边与 t，计算左上角 position，使边上的该点落在 lock_point
	var s: Vector2 = size
	var top_left := Vector2.ZERO
	match edge:
		0: # Left
			top_left = Vector2(lock_point.x, lock_point.y - t * s.y)
		1: # Right
			top_left = Vector2(lock_point.x - s.x, lock_point.y - t * s.y)
		2: # Top
			top_left = Vector2(lock_point.x - t * s.x, lock_point.y)
		3: # Bottom
			top_left = Vector2(lock_point.x - t * s.x, lock_point.y - s.y)
	position = top_left

func _on_resized() -> void:
	_align_to_lock_point()

func _on_minimum_size_changed() -> void:
	# 最小尺寸变化可能触发布局调整
	await get_tree().process_frame
	_align_to_lock_point()

func _on_viewport_resized() -> void:
	_align_to_lock_point()

# 在编辑器里改 inspector 的值时也立刻对齐
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_align_to_lock_point()
