extends Control

@export var items: Array[ItemData]

@onready var inventory: ColorRect = $Inventory
@onready var character: ColorRect = $Character

func _on_button_close_inventory_pressed() -> void:
	inventory.hide()

func _on_button_close_character_pressed() -> void:
	character.hide()

func _on_button_toggle_inventory_pressed() -> void:
	inventory.visible = not inventory.visible

func _on_button_toggle_character_info_pressed() -> void:
	character.visible = not character.visible

func _on_button_add_test_items_pressed() -> void:
	for item in items:
		if randi_range(1, 100) > 50:
			item = item.duplicate()
			(item as ItemData).shader_params = {"enable_enhance": true}
		GBIS.add_item("demo2_inventory", item)

func _on_button_save_pressed() -> void:
	GBIS.save()

func _on_button_load_pressed() -> void:
	GBIS.load()
