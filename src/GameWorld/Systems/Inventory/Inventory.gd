extends Node
class_name Inventory

var inventory_items = []
var max_capacity = 8
var gameworld_resource_configurations = load("res://src/GameWorld/GameWorldObjects/gameworld_object_config.tres").resources

const RESOURCE_LOAD_PATH = "res://src/GameWorld/GameWorldObjects/Resources/"

var InventoryItem = load("res://src/GameWorld/Systems/Inventory/InventoryItem/InventoryItem.tscn")

# TODO: define and load all inventory_item sounds in this interface
# GameWorld will populate the inventory menu with inventory items

# Called when the node enters the scene tree for the first time.
func _ready():
	#if not inventory_items and gameworld_resource_configurations:
	#	debug_load_items()
	pass
	
# DEBUG
func debug_load_items():
	inventory_items = []
	var types = ["apple", "sticks", "stones", "red", "blue", "green"]
	for type in types:
		add_item_from_resource_type(type)

func add_item_from_resource_type(resource_type):
	var new_item = InventoryItem.instance()
	var resource_type_config = gameworld_resource_configurations[resource_type]
	if resource_type_config.has("consume_sound"):
		new_item.set_consume_sound(load(RESOURCE_LOAD_PATH + resource_type_config["consume_sound"]))
	if resource_type_config.has("consume_value"):
		new_item.set_consume_value(resource_type_config["consume_value"])
	if resource_type_config.has("description"):
		new_item.set_description_to_speech(load(RESOURCE_LOAD_PATH + resource_type_config["description"]))
	if resource_type_config.has("identity_sound"):
		new_item.set_identity_sound(load(RESOURCE_LOAD_PATH + resource_type_config["identity_sound"]))
	if resource_type_config.has("name"):
		new_item.set_name_to_speech(load(RESOURCE_LOAD_PATH + resource_type_config["name"]))
	new_item.set_type(resource_type)
	inventory_items.append(new_item)
	add_child(new_item)

func get_consume_sound_at_index(index):
	if len(inventory_items) - 1 >= index:
		return inventory_items[index].get_consume_sound()
	return null

func get_description_to_speech_at_index(index):
	if len(inventory_items) - 1 >= index:
		return inventory_items[index].get_description_to_speech()
	return null

func get_free_spaces_count():
	return max_capacity - len(inventory_items)

func get_item_at_index(index):
	if len(inventory_items) - 1 >= index:
		return inventory_items[index]
	return null
	
func get_name_to_speech_at_index(index):
	if len(inventory_items) - 1 >= index:
		return inventory_items[index].get_name_to_speech()
	return null

func get_largest_index():
	return max(len(inventory_items)-1,0)

func get_item_count():
	return len(inventory_items)

func get_type_at_index(index):
	if len(inventory_items) - 1 >= index:
		return inventory_items[index].get_type()
	return null
	
func has_item_type(type):
	for item in inventory_items:
		if item.get_type() == type:
			return true
	return false

func has_multiple_items():
	if len(inventory_items) > 1:
		return true
	return false

func is_at_max_capacity():
	print("len inventory items: " + str(len(inventory_items)))
	if len(inventory_items) == max_capacity:
		return true
	return false
	
func is_empty():
	if len(inventory_items) == 0:
		return true
	return false

func load_items():
	# TODO: load player inventory from serialized data in file system
	inventory_items = []
	# DEBUG: temporary item load
	## debug_load_items()

func remove_item_at_index(item_index):
	if len(inventory_items) >= item_index:
		inventory_items.remove(item_index)

func remove_items_by_index(item_indecies_to_remove):
	var updated_inventory_items = []
	var item_index = 0
	while item_index < len(inventory_items):
		if not item_index in item_indecies_to_remove and item_index < len(inventory_items):
			updated_inventory_items.append(inventory_items[item_index])
		item_index = item_index + 1
	inventory_items = updated_inventory_items

