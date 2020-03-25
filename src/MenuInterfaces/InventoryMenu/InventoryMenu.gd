extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var current_index
var inventory_items = []
var marked_for_craft = []

const DEBUG_WHISPER_VOLUME = -35
const DEBUG_WHISPER_DELAY_LEFT = .22
const DEBUG_WHISPER_DELAY_RIGHT = .32

# options: items_list_menu, item_popup_menu, items_craft_menu
var substate

var debug_cycle_menu = false

var audio_craft_success_sound = load("res://src/MenuInterfaces/InventoryMenu/441812__fst180081__180081-hammer-on-anvil-01.wav")
var audio_craft_failed_sound = load("res://src/MenuInterfaces/InventoryMenu/141334__lluiset7__error-2.wav")
var audio_close_craft_alert = load("res://src/MenuInterfaces/InventoryMenu/141334__lluiset7__error-2.wav")

var speech_assist_examine = load("res://src/MenuInterfaces/InventoryMenu/speech_assist_examine.wav")
var speech_assist_consume = load("res://src/MenuInterfaces/InventoryMenu/speech_assist_consume.wav")
var speech_assist_craft = load("res://src/MenuInterfaces/InventoryMenu/speech_assist_craft.wav")
var speech_assist_cancel = load("res://src/MenuInterfaces/InventoryMenu/speech_assist_cancel.wav")
var speech_assist_cancel_craft = load("res://src/MenuInterfaces/InventoryMenu/speech_assist_cancel_craft_1.wav")

# DEBUG
var craft_mappings = {}
var gameworld_object_definitions
var InventoryItem

# Called when the node enters the scene tree for the first time.
func _ready():

	InventoryItem = load("res://src/MenuInterfaces/InventoryMenu/InventoryItem.tscn")
	current_index = 0
	debug_configure_audio_bus()
	debug_load_item_definitions()
	debug_load_name_to_speech()
	$NavigateSound.connect("finished",self,"on_NavigateSound_finished")
	substate = "items_list_menu"
	current_item_selected()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_pressed("menu_ui_assist"):
		describe_input_option_to_user()
	elif substate == "items_list_menu":
		if Input.is_action_just_pressed("menu_ui_right"):
			navigate_to_item("next")
		elif Input.is_action_just_pressed("menu_ui_left"):
			navigate_to_item("previous")
		elif Input.is_action_just_pressed("menu_ui_repeat"):
			current_item_selected()
		elif Input.is_action_just_pressed("inventory_menu_craft"):
			toggle_current_item_craft_mark()
		elif Input.is_action_just_pressed("inventory_menu_examine"):
			examine_selected_item()
		elif Input.is_action_just_pressed("inventory_menu_consume"):
			consume_selected_item()
		elif Input.is_action_just_pressed("inventory_menu_confirm_craft"):
			attempt_craft_with_marked_items()
	elif substate == "items_popup_menu":
		if Input.is_action_just_pressed("menu_ui_cancel"):
			pass #TODO
	else:
		print("ERROR: InventoryMenu has invalid substate")

# TODO: determine how to migrate this method to the Inventory scene
func add_inventory_item(type):
	var item_definition = gameworld_object_definitions["resources"][type]
	var pwd_path = "res://src/MenuInterfaces/InventoryMenu/"
	inventory_items.append(InventoryItem.instance())
	var current_capacity = len(inventory_items)
	add_child(inventory_items[current_capacity-1])
	inventory_items[current_capacity-1].set_type(type)
	inventory_items[current_capacity-1].set_name_to_speech(load(pwd_path + item_definition["name"]))
	inventory_items[current_capacity-1].set_description_to_speech(load(pwd_path + item_definition["description"]))
	inventory_items[current_capacity-1].set_whisper_delay_left(DEBUG_WHISPER_DELAY_LEFT)
	inventory_items[current_capacity-1].set_whisper_delay_left(DEBUG_WHISPER_DELAY_RIGHT)
	inventory_items[current_capacity-1].get_node("WhisperDelayLeft").connect("timeout",self,"on_WhisperDelayLeft_timeout")
	inventory_items[current_capacity-1].get_node("WhisperDelayRight").connect("timeout",self,"on_WhisperDelayRight_timeout")
	marked_for_craft.append(false)

func alert_left_end_reached():
	if not $AlertLeftEndReached.is_playing():
		$AlertLeftEndReached.play()
		Input.start_joy_vibration (0, 0, .8, .2)
		
func alert_marked_for_craft():
	Input.start_joy_vibration (0, 1, 0, .08)
	
func alert_right_end_reached():
	if not $AlertRightEndReached.is_playing():
		$AlertRightEndReached.play()
		Input.start_joy_vibration (0, 0, .8, .2)

func attempt_craft_with_marked_items():
	var items_to_craft_indecies = []
	var item_index = 0
	while item_index < len(inventory_items):
		if marked_for_craft[item_index]:
			items_to_craft_indecies.append(item_index)
		item_index = item_index + 1
	var craft_result = get_craft_result(items_to_craft_indecies)
	if craft_result:
		if not $CraftSuccessSound.is_playing():
			$CraftSuccessSound.play()
		# remove items_to_craft from inventory_items
		var updated_inventory_items = []
		item_index = 0
		while item_index < len(inventory_items):
			if not marked_for_craft[item_index]:
				updated_inventory_items.append(inventory_items[item_index])
			item_index = item_index + 1
		inventory_items = updated_inventory_items
		# add item_definitions[craft_result] to inventory_items
		add_inventory_item(craft_result)
	else:
		if not $CraftFailedSound.is_playing():
			$CraftFailedSound.play()
			
	for item_index in items_to_craft_indecies:
		marked_for_craft[item_index] = false

# TODO: initialize consumption mechanic
func consume_selected_item():
	pass

func current_item_selected(end_reached=false):
	if len(inventory_items) > 0:
		inventory_items[current_index].select()
		if marked_for_craft[current_index] and not end_reached:
			alert_marked_for_craft()
		
#DEBUG
func debug_configure_audio_bus():
	AudioServer.set_bus_volume_db (1, DEBUG_WHISPER_VOLUME)
	AudioServer.set_bus_volume_db (2, DEBUG_WHISPER_VOLUME)

#DEBUG
func debug_load_item_definitions():
	var gameworld_object_definitions_data = File.new()
	var file_name = "res://src/gameworld_object_definitions.json"
	if not gameworld_object_definitions_data.file_exists(file_name):
		print("ERROR: could not load %s" % file_name)
		return 
		
	gameworld_object_definitions_data.open(file_name, File.READ)
	gameworld_object_definitions_data = gameworld_object_definitions_data.get_as_text()
	
	gameworld_object_definitions = parse_json(gameworld_object_definitions_data)
	if not typeof(gameworld_object_definitions) == TYPE_DICTIONARY:
		print("ERROR: gameworld_object_definitions parse result invalid")
		return

	for resource_type in gameworld_object_definitions["resources"].keys():
		craft_mappings[resource_type] = gameworld_object_definitions["resources"][resource_type]["craft_mappings"]

#DEBUG
func debug_load_name_to_speech():
	var types = ["blue", "green", "red"]
	for type in types:
		add_inventory_item(type)

func describe_input_option_to_user():
	#TODO: determine how to structure this, and whether a singleton would be better
	if substate == "items_list_menu":
		if Input.is_action_just_pressed("menu_ui_right"):
			pass
		elif Input.is_action_just_pressed("menu_ui_left"):
			pass
		elif Input.is_action_just_pressed("menu_ui_repeat"):
			pass
		elif Input.is_action_just_pressed("inventory_menu_craft"):
			$InputAssistAudio.set_stream(speech_assist_craft)
			$InputAssistAudio.play()
		elif Input.is_action_just_pressed("inventory_menu_examine"):
			$InputAssistAudio.set_stream(speech_assist_examine)
			$InputAssistAudio.play()
		elif Input.is_action_just_pressed("menu_ui_cancel"):
			$InputAssistAudio.set_stream(speech_assist_cancel)
			$InputAssistAudio.play()
		elif Input.is_action_just_pressed("inventory_menu_consume"):
			$InputAssistAudio.set_stream(speech_assist_consume)
			$InputAssistAudio.play()

func examine_selected_item():
	inventory_items[current_index].read_description()

func get_craft_result(items_to_craft_indecies):
	if items_to_craft_indecies:
		var items_to_craft = []
		
		for item_index in items_to_craft_indecies:
			items_to_craft.append(inventory_items[item_index].get_type())
		items_to_craft.sort()
		
		for craft_result in craft_mappings.keys():
			for craft_mapping in craft_mappings[craft_result]:
				print("craft mapping: " + str(craft_mapping))
				craft_mapping.sort()
				if craft_mapping == items_to_craft:
					return craft_result
	return false

func list_items_marked_for_craft():
	var index = 0
	if inventory_items:
		while index < len(inventory_items):
			if marked_for_craft[index]:
				while inventory_items[index].get_node("NameToSpeech").is_playing():
					pass
				inventory_items[index].speak_name()
			index = index + 1

func load_menu_end_alert_positions():
	# TODO: use screen resolution to position 2D Audio alert nodes for reaching menu end
	pass

func navigate_to_item(direction):
	var end_reached = false
	Input.stop_joy_vibration(0)
	if direction == "next":
		if current_index == len(inventory_items) - 1 or len(inventory_items) == 0:
			alert_right_end_reached()
			end_reached = true
		else:
			inventory_items[0].stop_all_audio()
			current_index = 0	
			current_index = current_index + 1
			$NavigateSound.play()
		if len(inventory_items) > 1:
			inventory_items[current_index-1].stop_all_audio()
		if len(inventory_items) > 0:
			inventory_items[current_index].stop_all_audio()

	elif direction == "previous":
		if current_index == 0:
			alert_left_end_reached()
			end_reached = true
		else:
			inventory_items[len(inventory_items) - 1].stop_all_audio()
			current_index = len(inventory_items) - 1
			current_index = current_index - 1
			$NavigateSound.play()
			if len(inventory_items) > 1:
				inventory_items[current_index+1].stop_all_audio()
			if len(inventory_items) > 0:
				inventory_items[current_index].stop_all_audio()
				
	current_item_selected(end_reached)

func on_NavigateSound_finished():
	current_item_selected()

func on_WhisperDelayLeft_timeout():	
	if current_index > 0:
		inventory_items[current_index-1].whisper_name_left()

func on_WhisperDelayRight_timeout():
	if current_index < len(inventory_items) - 1:
		inventory_items[current_index+1].whisper_name_right()

func toggle_current_item_craft_mark():
	if not $InitiateCraftAlert.is_playing():
		$InitiateCraftAlert.play()
	marked_for_craft[current_index] = not marked_for_craft[current_index]
	alert_marked_for_craft()
	
