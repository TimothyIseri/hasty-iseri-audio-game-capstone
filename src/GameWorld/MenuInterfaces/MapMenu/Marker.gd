extends Area2D
class_name Marker

var associated_object
var can_detect = true
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func get_associated_object():
	return associated_object

func get_can_detect():
	return can_detect

func set_associated_object(arg_object):
	associated_object = arg_object

func set_can_detect(arg):
	can_detect = arg
