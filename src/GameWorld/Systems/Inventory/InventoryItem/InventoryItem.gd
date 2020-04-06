extends Node
class_name InventoryItem

var type
var has_consume = false

var consume_sound
var consume_value
var identity_sound
var name_to_speech
var description_to_speech

# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: implement audio resource loading; load all inventory item sounds here?
	type = "empty"

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
	
func consume():
	pass

func get_consume_sound():
	return consume_sound
	
func get_consume_value():
	return consume_value

func get_description_to_speech():
	return description_to_speech

func get_identity_sound():
	return identity_sound

func get_name_to_speech():
	return name_to_speech
	
func get_type():
	return type

func set_consume_sound(arg_consume_sound):
	consume_sound = arg_consume_sound

func set_consume_value(arg_consume_value):
	consume_value = arg_consume_value

func set_description_to_speech(arg_description_to_speech):
	description_to_speech = arg_description_to_speech

func set_identity_sound(arg_identity_sound):
	identity_sound = arg_identity_sound

func set_name_to_speech(arg_name_to_speech):
	name_to_speech = arg_name_to_speech
	
func set_type(arg_type="empty"):
	self.type = arg_type

