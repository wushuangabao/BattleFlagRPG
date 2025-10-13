extends Control

@export var items: Array[ItemData]

@onready var inventory: ColorRect = $Inventory
@onready var storage: ColorRect = $Storage
@onready var inventory_view: InventoryView = %InventoryView

func _ready() -> void:
	GBIS.add_quick_move_relation("demo1_inventory", "demo1_storage")
	GBIS.add_quick_move_relation("demo1_storage", "demo1_inventory")

func _on_button_close_inventory_pressed() -> void:
	inventory.hide()

func _on_button_close_storage_pressed() -> void:
	storage.hide()

func _on_button_toggle_inventory_pressed() -> void:
	inventory.visible = not inventory.visible

func _on_button_toggle_storage_pressed() -> void:
	storage.visible = not storage.visible

func _on_button_add_test_items_pressed() -> void:
	for item in items:
		if randi_range(1, 100) > 50:
			item = item.duplicate()
			(item as ItemData).shader_params = {"enable_enhance": true}
		GBIS.add_item("demo4_inventory", item)

func _on_button_save_pressed() -> void:
	GBIS.save()

func _on_button_load_pressed() -> void:
	GBIS.load()

func _on_button_change_to_inv_pressed() -> void:
	inventory_view.change_data_source("demo4_inventory")

func _on_button_change_to_storage_pressed() -> void:
	inventory_view.change_data_source("demo4_storage")
