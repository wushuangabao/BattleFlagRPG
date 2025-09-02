class_name UI_Area_Detector
extends Area2D

var is_mouse_over_ui := false

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	is_mouse_over_ui = true

func _on_mouse_exited():
	is_mouse_over_ui = false
