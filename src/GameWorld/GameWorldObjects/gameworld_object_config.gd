extends Resource

const GAMEWORLD_OBJECT_CONFIG_PATH = "res://src/GameWorld/GameWorldObjects/gameworld_object_definitions.json"
export var artifacts = {}
export var obstacles = {\
	"tree": {
		"identity_sound": "tree.wav",
		"resource": "apple"
	},
	"boulder":{
		"identity_sound": "rock.wav",
		"resource": "stones"
	},
	"bush":{
		"identity_sound": "bush.wav",
		"resource": "sticks"
	}
}
export var resources = {\
	"apple": {
		  "name": "speech_apple.wav",
		  "description": "speech_apple_description.wav",
		  "consume_sound": "apple-crunch-14.wav",
		  "consume_value": 1,
		  "craft_mappings": []
	  },
	  "sticks": {
		  "name": "speech_sticks.wav",
		  "description": "speech_sticks_description.wav",
		  "consume_value": 0,
		  "craft_mappings": []
	  },
	  "stones": {
		  "name": "speech_stones.wav",
		  "description": "speech_stones_description.wav",
		  "consume_value": 0,
		  "craft_mappings": []
	  },
	  "axe": {
		  "name": "speech_axe.wav",
		  "description": "speech_axe_description.wav",
		  "identity_sound": "axe-chop-into-wood-little-debris.wav",
		  "consume_value": 0,
		  "craft_mappings": [ ["sticks", "stones"] ]
	  }
}
export var waypoints = {\
	"waypoint1": {
		"name": "speech_waypoint1.wav"
	  },
	  "waypoint2": {
		"name": "speech_waypoint2.wav"
	  },
	  "waypoint3": {
		"name": "speech_waypoint3.wav"
	  },
	  "waypoint4": {
		"name": "speech_waypoint4.wav"
	  }
}

export var craft_mappings = {}

# Called when the node enters the scene tree for the first time.
func _init():
	load_object_configurations()

func load_object_configurations():
	for resource_type in resources.keys():
		craft_mappings[resource_type] = resources[resource_type]["craft_mappings"]
