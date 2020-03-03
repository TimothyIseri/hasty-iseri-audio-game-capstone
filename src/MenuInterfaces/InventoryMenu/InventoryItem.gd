extends Node

# Options: none
var type
var has_examine = false
var has_consume = false
var has_craft = false
var craft_compatibility_list = []
# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: implement audio resource loading; load all inventory item sounds here?
	
	type = "empty"


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func add_craft_compatible_item(items):
	if typeof(items) == TYPE_STRING:
		items = [items]
	for item in items:
		craft_compatibility_list.append(item)
		
func consume():
	if not $ConsumeSound.is_playing():
		$ConsumeSound.play()

func deselect():
	stop_all_audio()
	
func load_type_audio():
	if type:
		pass

func issue_audio_id():
	$IdentitySound.play()

func read_description():
	if not $DescriptionToSpeech.is_playing():
		$DescriptionToSpeech.play()
	
func select():
	$NameToSpeech.set_bus('Master')
	$WhisperDelayLeft.start()
	$WhisperDelayRight.start()
	issue_audio_id()
	speak_name()

func set_audio_id(audio_id):
	$IdentitySound.set_stream(audio_id)

func set_description_to_speech(description_to_speech):
	$DescriptionToSpeech.set_stream(description_to_speech)

func set_name_to_speech(name_to_speech):
	$NameToSpeech.set_stream(name_to_speech)
	
func set_type(type="empty"):
	self.type = type
	
func set_whisper_delay_left(delay):
	$WhisperDelayLeft.wait_time = delay
	
func set_whisper_delay_right(delay):
	$WhisperDelayRight.wait_time = delay

func speak_name():
	if not $NameToSpeech.is_playing():
		$NameToSpeech.play()

func stop_all_audio():
	if $ConsumeSound.is_playing():
		$ConsumeSound.stop()
	if $DescriptionToSpeech.is_playing():
		$DescriptionToSpeech.stop()
	if $IdentitySound.is_playing():
		$IdentitySound.stop()
	if $NameToSpeech.is_playing():
		$NameToSpeech.stop()

func whisper_name_left():
	print($NameToSpeech.get_bus())
	$NameToSpeech.set_bus("L_UI_Whisper")
	print($NameToSpeech.get_bus())
	speak_name()
	#$NameToSpeech.bus = 'Master'

func whisper_name_right():
	$NameToSpeech.set_bus("R_UI_Whisper")
	speak_name()
	#$NameToSpeech.bus = 'Master'
	
