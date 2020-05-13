extends Node

signal energy_level_decreased
signal energy_level_increased
signal energy_level_zero

var energy_level

var audio_energy_decreased = load("res://src/GameWorld/Systems/220205__gameaudio__teleport-darker.wav")
var audio_energy_increased = load("res://src/GameWorld/Systems/220173__gameaudio__spacey-1up-power-up.wav")
var audio_magnitude = load("res://src/GameWorld/Systems/485076__inspectorj__heartbeat-regular-single-01-01-loop.wav")

var magnitude_feedback_active = false
var magnitude_feedback_timer = 0
var magnitude_velocity = 0

var horizontal_max = 1280 # TODO: get from resolution definition mechanism

# DEBUG
const DEBUG_ENERGY_SYSTEMS = false

# Called when the node enters the scene tree for the first time.
func _ready():
	energy_level = 0
	$MagnitudeAudio.set_stream(audio_magnitude)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if magnitude_feedback_active:
		update_magnitude_feedback_position(delta)
	# DEBUG
	if DEBUG_ENERGY_SYSTEMS:
		if Input.is_action_just_pressed("ui_select"):
			init_magnituted_feedback()
		elif Input.is_action_just_pressed("ui_up"):
			increase(1)
			print("Energy level: " + str(energy_level))
		elif Input.is_action_just_pressed("ui_down"):
			decrease(1)
			print("Energy level: " + str(energy_level))

func decrease(level_delta):
	if level_delta > 0:
		energy_level = energy_level - level_delta
		if energy_level <= 0:
			emit_signal("energy_level_zero")
		issue_marginal_feedback(audio_energy_decreased)

func get_decrease_audio_feedback():
	return audio_energy_decreased

func get_level():
	return energy_level

func get_increase_audio_feedback():
	return audio_energy_increased

func increase(level_delta):
	if level_delta > 0:
		energy_level = energy_level + level_delta
	issue_marginal_feedback(audio_energy_increased)

func init_magnituted_feedback():
	if energy_level > 0:
		magnitude_feedback_active = true
		magnitude_feedback_timer = energy_level
		magnitude_velocity = horizontal_max / energy_level*3

func issue_magnitude_feedback():
	if not $MagnitudeAudio.is_playing():
		$MagnitudeAudio.play()

func issue_marginal_feedback(feedback):
	$MarginAudio.set_stream(feedback)
	if $MarginAudio.is_playing():
		$MarginAudio.stop()
	$MarginAudio.play()

func reset_magnitude_audio():
	magnitude_feedback_timer = 0
	magnitude_feedback_active = false
	$MagnitudeAudio.position.x = 0

func set_level(arg_level):
	energy_level = arg_level

func update(value):
	if value > 0:
		increase(value)
	elif value < 0:
		decrease(value)

func update_magnitude_feedback_position(delta):
	if $MagnitudeAudio.position.x < horizontal_max:
		$MagnitudeAudio.position.x = $MagnitudeAudio.position.x + magnitude_velocity*delta
		issue_magnitude_feedback()
	elif $MagnitudeAudio.position.x >= horizontal_max and not $MagnitudeAudio.is_playing():
		reset_magnitude_audio()


