extends AbstractController

@onready var count_text: Label = $CountText
@onready var btn_add: Button = $BtnAdd
@onready var btn_sub: Button = $BtnSub

func _ready() -> void:
	set_architecture(CounterAppArchitecture.new())
	btn_add.pressed.connect(add)
	btn_sub.pressed.connect(sub)
	get_model(CounterAppModel).count.register_and_refresh(
		func(count):
			count_text.text = str(count);
	)

func add():
	get_model(CounterAppModel).count.value += 1

func sub():
	get_model(CounterAppModel).count.value -= 1
