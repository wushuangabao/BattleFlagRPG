@tool
extends Control

@export_range(0.0, 100.0, 1.0) var A_min := 80.0
@export_range(0.0, 200.0, 1.0) var A_max := 100.0
@export_range(0.0, 100.0, 1.0) var D_min := 0.0
@export_range(0.0, 200.0, 1.0) var D_max := 80.0
@export_range(8, 128, 1) var grid_x := 16
@export_range(8, 128, 1) var grid_y := 16

@onready var label_A  : Label   = $"../HBoxContainer/Label_A"
@onready var slider_A : HSlider = $"../HBoxContainer/HSlider_A"
@onready var lable_D  : Label   = $"../HBoxContainer2/Label_D"
@onready var slider_D : HSlider = $"../HBoxContainer2/HSlider_D"

@onready var label : Label = $"../Label"
var _A := 0.0
var _D := 0.0
var _P := 0.0

var calculator : Callable = Resolver.calclulate_hit_chance

func calc_value(A: float, D: float) -> float:
	var value = calculator.call(A * 0.01, D * 0.01)
	return value

func p_to_color(p: float) -> Color:
	# 0→蓝, 0.5→青, 1→红 的渐变
	var t := clamp(p, 0.0, 1.0)
	return Color.from_hsv(lerp(0.65, 0.0, t), 0.85, 0.95, 1.0)

func _ready() -> void:
	_on_slider_drag_ended(true)

func _draw():
	if size.x < size.y:
		size.x = size.y
	else:
		size.y = size.x
	var cell_width := size.x / float(grid_x)
	var cell_height := size.y / float(grid_y)
	for iy in range(grid_y):
		var dy := float(iy) / float(grid_y - 1)
		var D := lerp(D_min, D_max, dy)
		for ix in range(grid_x):
			var dx := float(ix) / float(grid_x - 1)
			var A := lerp(A_min, A_max, dx)
			var p := calc_value(A, D)
			var col := p_to_color(p)
			var cell := Rect2(Vector2(ix * cell_width, iy * cell_height), Vector2(cell_width, cell_height))
			draw_rect(cell, col, true)
	_draw_iso(_P, Color(1, 1, 1, 0.5))
	_plot_iso_point(slider_A.value / slider_A.max_value * grid_x, slider_D.value / slider_D.max_value * grid_y, Color(0, 0, 0, 0.95))

func _draw_iso(th: float, clo: Color) -> void:
	# 简单 marching squares（粗略版）
	for iy in range(0, grid_y - 1):
		for ix in range(0, grid_x - 1):
			var A00 := lerp(A_min, A_max, float(ix) / float(grid_x - 1))
			var D00 := lerp(D_min, D_max, float(iy) / float(grid_y - 1))
			var A10 := lerp(A_min, A_max, float(ix+1) / float(grid_x - 1))
			var D01 := lerp(D_min, D_max, float(iy+1) / float(grid_y - 1))
			var p00 := calc_value(A00, D00)
			var p10 := calc_value(A10, D00)
			var p01 := calc_value(A00, D01)
			var p11 := calc_value(A10, D01)
			# 横边插值
			if (p00 - th) * (p10 - th) < 0.0:
				var t := (th - p00) / (p10 - p00)
				var x := lerp(float(ix), float(ix+1), t)
				var y := float(iy)
				_plot_iso_point(x, y, clo)
			if (p01 - th) * (p11 - th) < 0.0:
				var t2 := (th - p01) / (p11 - p01)
				var x2 := lerp(float(ix), float(ix+1), t2)
				var y2 := float(iy+1)
				_plot_iso_point(x2, y2, clo)
			# 竖边插值
			if (p00 - th) * (p01 - th) < 0.0:
				var t3 := (th - p00) / (p01 - p00)
				var x3 := float(ix)
				var y3 := lerp(float(iy), float(iy+1), t3)
				_plot_iso_point(x3, y3, clo)
			if (p10 - th) * (p11 - th) < 0.0:
				var t4 := (th - p10) / (p11 - p10)
				var x4 := float(ix+1)
				var y4 := lerp(float(iy), float(iy+1), t4)
				_plot_iso_point(x4, y4, clo)

func _plot_iso_point(gx: float, gy: float, col: Color) -> Vector2:
	var cell_width := size.x / float(grid_x)
	var cell_height := size.y / float(grid_y)
	var p := Vector2(gx * cell_width, gy * cell_height) + Vector2(0.5 * cell_width, 0.5 * cell_height)
	draw_circle(p, 1.0, col)
	return p

func _on_slider_drag_ended(_changed: bool) -> void:
	if not _changed:
		return
	_A = slider_A.value / slider_A.max_value * (A_max - A_min) + A_min
	_D = slider_D.value / slider_D.max_value * (D_max - D_min) + D_min
	label_A.text = "A = %.2f" % _A
	lable_D.text = "D = %.2f" % _D
	_P = calc_value(_A, _D)
	label.text = "%.2f" % _P
	if Engine.is_editor_hint():
		queue_redraw()
