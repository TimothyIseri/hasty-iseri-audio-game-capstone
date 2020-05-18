extends Control
class_name InventoryMenu

signal closed
signal item_consumed

var current_index
var inventory = null
var marked_for_craft = []
var craft_mappings = {}
var gameworld_resource_configurations = load("res://src/GameWorld/GameWorldObjects/gameworld_object_config.tres").resources

var gameworld_object_configurations = load("res://src/GameWorld/GameWorldObjects/gameworld_object_config.tres")

var audio_consume_failed_sound = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/141334__lluiset7__error-2.wav")
var audio_craft_success_sound = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/441812__fst180081__180081-hammer-on-anvil-01.wav")
var audio_craft_failed_sound = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/141334__lluiset7__error-2.wav")
var audio_close_craft_alert = load("res://src/GameWorld/MenuInterfaces/419494__plasterbrain__high-tech-ui-cancel.wav")
var audio_free_space = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/411221__andersholm__rustling-of-chips-bag.wav")
var audio_mark_for_craft = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/418850__kierankeegan__rachet-click.wav")
var audio_navigate_sound = load("res://src/GameWorld/MenuInterfaces/213148__complex-waveform__click.wav")
var audio_occupied_space = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/TylerHasty_key01.wav")
var audio_unmark_for_craft = load("res://src/GameWorld/MenuInterfaces/419494__plasterbrain__high-tech-ui-cancel.wav")

var speech_assist_cancel = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/speech_assist_cancel.wav")
var speech_assist_consume = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/speech_assist_consume.wav")
var speech_assist_craft = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/speech_assist_craft.wav")
var speech_assist_examine = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/speech_assist_examine.wav")
var speech_free_spaces = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/speech_free_spaces.wav")
var speech_inventory_menu = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/speech_inventory_menu.wav")
var speech_marked_for_craft = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/speech_marked_for_craft.wav")
var speech_none = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/speech_none.wav")
var speech_occupied_spaces = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/speech_occupied_spaces.wav")

# Nodes
#onready var AlertLeftEndReached = get_node("AlertLeftEndReached")
#onready var AlertRightEndReached = get_node("AlertRightEndReached")
#onready var InputAssistAudio = get_node("InputAssistAudio")
#onready var SimpleSFXQueue = get_node("SimpleSFXQueue")
#onready var WhisperAudioPlayerQueue = get_node("WhisperAudioPlayerQueue")

# DEBUG
const DEBUG_WHISPER_VOLUME = -33
const DEBUG_WHISPER_DELAY_LEFT = .22
const DEBUG_WHISPER_DELAY_RIGHT = .32
const DEBUG_SIMULTANEOUS_MARK_FOR_CRAFT_FEEDBACK = true

var whisper_delay_left_timer_active = false
var whisper_delay_right_timer_active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	current_index = 0
	if not inventory:
		inventory = Inventory.new()
	for resource_type in gameworld_object_configurations.resources.keys():
		craft_mappings[resource_type] = gameworld_object_configurations.resources[resource_type]["craft_mappings"]
	
	$CloseMenuSound.connect("finished",self,"on_CloseMenuSound_finished")
	$ConsumeSound.connect("finished",self,"on_ConsumeSound_finished")
	$WhisperAudioPlayerQueue.add_primary_stream(speech_inventory_menu)
	$WhisperAudioPlayerQueue.commit()
	debug_configure_audio_bus()
	current_item_selected()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_pressed("menu_ui_assist"):
		describe_input_option_to_user()
	else:
		if Input.is_action_just_pressed("menu_ui_right"):
			stop_all_audio()
			navigate_to_item("next")
		elif Input.is_action_just_pressed("menu_ui_left"):
			stop_all_audio()
			navigate_to_item("previous")
		elif Input.is_action_just_pressed("menu_ui_repeat"):
			stop_all_audio()
			current_item_selected()
		elif Input.is_action_just_pressed("inventory_menu_craft"):
			stop_all_audio()
			toggle_current_item_craft_mark()
		elif Input.is_action_just_pressed("inventory_menu_examine"):
			stop_all_audio()
			examine_selected_item()
		elif Input.is_action_just_pressed("inventory_menu_consume"):
			stop_all_audio()
			consume_selected_item()
		elif Input.is_action_just_pressed("inventory_menu_confirm_craft"):
			stop_all_audio()
			attempt_craft_with_marked_items()
		elif Input.is_action_just_pressed("inventory_menu_get_status"):
			stop_all_audio()
			read_status()
		elif Input.is_action_just_pressed("menu_ui_cancel"):
			stop_all_audio()
			close()

func alert_left_end_reached():
	if not $AlertLeftEndReached.is_playing():
		$AlertLeftEndReached.play()
		Input.start_joy_vibration (0, 0, .8, .2)
		
func alert_is_marked_for_craft():
	Input.start_joy_vibration (0, 1, 0, .08)
	
func alert_right_end_reached():
	if not $AlertRightEndReached.is_playing():
		$AlertRightEndReached.play()
		Input.start_joy_vibration (0, 0, .8, .2)

func attempt_craft_with_marked_items():
	var craft_result = get_craft_result(marked_for_craft)
	if craft_result:
		issue_craft_success_feedback()
		remove_crafted_items_from_inventory()
		inventory.add_item_from_resource_type(craft_result)
		current_index = inventory.get_largest_index()
		current_item_selected()
	else:
		issue_craft_failed_feedback()
			
	marked_for_craft = []

func close():
	$CloseMenuSound.play()

# TODO: initialize consumption mechanic
func consume_selected_item():
	if not inventory.is_empty():
		if inventory.get_item_at_index(current_index).get_consume_value() == 0:
			$WhisperAudioPlayerQueue.add_primary_stream(audio_consume_failed_sound)
			$WhisperAudioPlayerQueue.commit()
		else:
			#$WhisperAudioPlayerQueue.add_primary_stream(inventory.get_name_to_speech_at_index(current_index))
			#$WhisperAudioPlayerQueue.commit()
			$ConsumeSound.set_stream(inventory.get_consume_sound_at_index(current_index))
			$ConsumeSound.play()
			var consume_value = inventory.get_item_at_index(current_index).get_consume_value()
			inventory.remove_item_at_index(current_index)
			emit_signal("item_consumed", consume_value)

func current_item_selected(end_reached=false):
	if not inventory.is_empty():
		$WhisperAudioPlayerQueue.add_primary_stream(inventory.get_name_to_speech_at_index(current_index))
		if inventory.has_multiple_items():
			if current_index > 0:
				$WhisperAudioPlayerQueue.add_whisper_left_stream(inventory.get_name_to_speech_at_index(current_index - 1), 
						DEBUG_WHISPER_DELAY_LEFT)
			if current_index < inventory.get_largest_index():
				$WhisperAudioPlayerQueue.add_whisper_right_stream(inventory.get_name_to_speech_at_index(current_index + 1), 
						DEBUG_WHISPER_DELAY_RIGHT)
		$WhisperAudioPlayerQueue.commit()
		if current_index in marked_for_craft and not end_reached:
			alert_is_marked_for_craft()
		
#DEBUG
func debug_configure_audio_bus():
	AudioServer.set_bus_volume_db (1, DEBUG_WHISPER_VOLUME)
	AudioServer.set_bus_volume_db (2, DEBUG_WHISPER_VOLUME)

func describe_input_option_to_user():
	#TODO: determine how to structure this, and whether a singleton would be better
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
	$WhisperAudioPlayerQueue.add_primary_stream(inventory.get_name_to_speech_at_index(current_index))
	$WhisperAudioPlayerQueue.commit()
	$WhisperAudioPlayerQueue.add_primary_stream(inventory.get_description_to_speech_at_index(current_index))
	$WhisperAudioPlayerQueue.commit()

func get_craft_result(items_to_craft_indecies):
	if items_to_craft_indecies:
		var items_to_craft = get_items_to_craft()

		for craft_result in craft_mappings.keys():
			for craft_mapping in craft_mappings[craft_result]:
				print("craft mapping: " + str(craft_mapping))
				craft_mapping.sort()
				if craft_mapping == items_to_craft:
					return craft_result
	return false

func get_items_to_craft():
	var items_to_craft = []
	for item_index in marked_for_craft:
		items_to_craft.append(inventory.get_type_at_index(item_index))
	items_to_craft.sort()
	return items_to_craft

func issue_craft_failed_feedback():
	$SimpleSFXQueue.add(audio_craft_failed_sound)

func issue_craft_success_feedback():
	$SimpleSFXQueue.add(audio_craft_success_sound)

func list_free_spaces():
	var index = 0
	$WhisperAudioPlayerQueue.add_primary_stream(speech_free_spaces)
	$WhisperAudioPlayerQueue.commit()
	if not inventory.is_empty():
		while index < inventory.get_free_spaces_count():
			$WhisperAudioPlayerQueue.add_primary_stream(audio_free_space)
			$WhisperAudioPlayerQueue.commit()
			index = index + 1
	else:
		$WhisperAudioPlayerQueue.add_primary_stream(speech_none)
		$WhisperAudioPlayerQueue.commit()
			
func list_items_marked_for_craft():
	$WhisperAudioPlayerQueue.add_primary_stream(speech_marked_for_craft)
	$WhisperAudioPlayerQueue.commit()
	
	if len(marked_for_craft) > 0:
		for item_index in marked_for_craft:
			$WhisperAudioPlayerQueue.add_primary_stream(inventory.get_name_to_speech_at_index(item_index))
			$WhisperAudioPlayerQueue.commit()
	else:
		$WhisperAudioPlayerQueue.add_primary_stream(speech_none)
		$WhisperAudioPlayerQueue.commit()

func list_occupied_spaces():
	var index = 0
	$WhisperAudioPlayerQueue.add_primary_stream(speech_occupied_spaces)
	$WhisperAudioPlayerQueue.commit()
	if not inventory.is_empty():
		while index < inventory.get_item_count():
			$WhisperAudioPlayerQueue.add_primary_stream(audio_occupied_space)
			$WhisperAudioPlayerQueue.commit()
			index = index + 1
	else:
		$WhisperAudioPlayerQueue.add_primary_stream(speech_none)
		$WhisperAudioPlayerQueue.commit()

func load_craft_mappings(external_craft_mappings):
	if external_craft_mappings == null:
		craft_mappings = gameworld_object_configurations.craft_mappings
	else:
		craft_mappings = external_craft_mappings

func load_inventory(external_inventory : Inventory):
	if external_inventory == null:
		inventory = Inventory.new()
	else:
		inventory = external_inventory
	
func load_menu_end_alert_positions():
	# TODO: use screen resolution to position 2D Audio alert nodes for reaching menu end
	pass

func navigate_to_item(direction):
	var end_reached = false
	var add_val = 0
	Input.stop_joy_vibration(0)
	stop_all_audio()
	if direction == "next":
		if current_index == inventory.get_largest_index():
			alert_right_end_reached()
			end_reached = true
		else:
			add_val = 1
	elif direction == "previous":
		if current_index == 0:
			alert_left_end_reached()
			end_reached = true
		else:
			add_val = -1
			
	if inventory.has_multiple_items() and not end_reached:
		$WhisperAudioPlayerQueue.add_primary_stream(audio_navigate_sound)
		$WhisperAudioPlayerQueue.commit()
	current_index = current_index + add_val
	current_item_selected(end_reached)

func on_CloseMenuSound_finished():
	emit_signal("closed")

func on_ConsumeSound_finished():
	emit_signal("closed")

func read_status():
	list_occupied_spaces()
	list_free_spaces()
	list_items_marked_for_craft()

func remove_crafted_items_from_inventory():
	inventory.remove_items_by_index(marked_for_craft)
		
func set_whisper_delay_left(delay):
	$WhisperDelayLeft.wait_time = delay
	
func set_whisper_delay_right(delay):
	$WhisperDelayRight.wait_time = delay

func stop_all_audio():
	$WhisperAudioPlayerQueue.stop_and_clear()
	$SimpleSFXQueue.stop_and_clear()

func stop_all_feedback():
	stop_all_audio()
	Input.stop_joy_vibration(0)

func toggle_current_item_craft_mark():
	if not current_index in marked_for_craft:
		marked_for_craft.append(current_index)
		if DEBUG_SIMULTANEOUS_MARK_FOR_CRAFT_FEEDBACK: 
			$SimpleSFXQueue.add(audio_mark_for_craft)
		else:
			$WhisperAudioPlayerQueue.add_primary_stream(audio_mark_for_craft)
			$WhisperAudioPlayerQueue.commit()
		alert_is_marked_for_craft()
	else:
		marked_for_craft.remove(current_index)
		if DEBUG_SIMULTANEOUS_MARK_FOR_CRAFT_FEEDBACK: 
			$SimpleSFXQueue.add(audio_unmark_for_craft)
		else:
			$WhisperAudioPlayerQueue.add_primary_stream(audio_unmark_for_craft)
			$WhisperAudioPlayerQueue.commit()
	print(str(marked_for_craft))
	$WhisperAudioPlayerQueue.add_primary_stream(inventory.get_name_to_speech_at_index(current_index))
	$WhisperAudioPlayerQueue.commit()
	

	
