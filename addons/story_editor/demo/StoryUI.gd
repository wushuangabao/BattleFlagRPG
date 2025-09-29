extends Control
class_name StoryUI

@onready var choices_vbox: VBoxContainer = %Choices

var on_choice: Callable

func show_line(speaker: String, line: String) -> void:
	_clear_choices()

func show_choices(opts: PackedStringArray, on_choose: Callable) -> void:
	_clear_choices()
	on_choice = on_choose
	for i in opts.size():
		var b := Button.new()
		b.text = "%d. %s" % [i+1, opts[i]]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			on_choice.call(i)
		)
		choices_vbox.add_child(b)

func _clear_choices() -> void:
	for c in choices_vbox.get_children():
		c.queue_free()
