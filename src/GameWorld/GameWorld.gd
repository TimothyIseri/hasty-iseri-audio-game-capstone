extends Node

const GAMEWORLD_OBJECT_CONFIG_PATH = "res://src/GameWorld/GameWorldObjects/gameworld_object_definitions.json"
const DEFAULT_ENERGY_LEVEL = 5

var paused = false
var gameworld_object_configurations
var gameworld_resource_craft_mappings = {}
var inventory

var objects = {"artifacts": null, "obstacles": null, "resources": null, "waypoints": null}

var InventoryMenu = load("res://src/GameWorld/MenuInterfaces/InventoryMenu/InventoryMenu.tscn")
var MapMenu = load("res://src/GameWorld/MenuInterfaces/MapMenu/MapMenu.tscn")
var GameWorldResource = load("res://src/GameWorld/GameWorldObjects/Resources/GameWorldResource.tscn")
var GameWorldWaypoint= load("res://src/GameWorld/GameWorldObjects/Waypoints/GameWorldWaypoint.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_object_configurations()
	load_waypoints()
	configure_gameworld_objects()
	load_inventory()
	# TODO: load energy level from saved state or initialize at a default value
	$EnergyLevel.set_level(DEFAULT_ENERGY_LEVEL)
	$Map/Ambiance.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not paused:
		if Input.is_action_just_pressed("gameworld_open_inventory_menu"):
			open_inventory_menu()
		elif Input.is_action_just_pressed("gameworld_energy_level"):
			$EnergyLevel.init_magnituted_feedback()
		if Input.is_action_just_pressed("gameworld_open_map_menu"):
			open_map_menu()

func configure_gameworld_artifact():
	pass # TODO

func configure_gameworld_objects():
	$Map/Player.connect("obstacle_harvested", self, "on_Obstacle_harvested")
	configure_gameworld_artifact()
	configure_gameworld_obstacle()
	configure_gameworld_resource()
	configure_gameworld_waypoint()

func configure_gameworld_obstacle():
	for gameworld_obstacle in get_tree().get_nodes_in_group("obstacles"):
		var type = gameworld_obstacle.get_type()
		var LOAD_PATH = "res://src/GameWorld/GameWorldObjects/Obstacles/"
		var gameworld_obstacle_config = gameworld_object_configurations["obstacles"][type]

		if gameworld_obstacle_config.has("identity_sound"):
			gameworld_obstacle.set_identity_sound(load(LOAD_PATH + gameworld_obstacle_config["identity_sound"]))
		if gameworld_obstacle_config.has("resource"):
			gameworld_obstacle.add_to_group("harvestable")
			gameworld_obstacle.set_resource(gameworld_obstacle_config["resource"])
			var new_resource = GameWorldResource.instance()
			new_resource.set_type(gameworld_object_configurations["obstacles"][type]["resource"])
			new_resource.add_to_group("resources")
			new_resource.translation = gameworld_obstacle.translation
			gameworld_obstacle.add_child(new_resource)

func configure_gameworld_resource():
	for gameworld_resource in get_tree().get_nodes_in_group("resources"):
		var type = gameworld_resource.get_type()
		var LOAD_PATH = "res://src/GameWorld/GameWorldObjects/Resources/"
		var gameworld_resource_config = gameworld_object_configurations["resources"][type]
		
		if gameworld_resource_config.has("identity_sound"):
			gameworld_resource.set_identity_sound(load(LOAD_PATH + gameworld_resource_config["identity_sound"]))
		if gameworld_resource_config.has("name"):
			gameworld_resource.set_name_to_speech(load(LOAD_PATH + gameworld_resource_config["name"]))
		if gameworld_resource_config.has("description"):
			gameworld_resource.set_description_to_speech(load(LOAD_PATH + gameworld_resource_config["description"]))
		if gameworld_resource_config.has("consume_sound"):
			gameworld_resource.set_consume_sound(load(LOAD_PATH + gameworld_resource_config["consume_sound"]))
		if gameworld_resource_config.has("consume_value"):
			gameworld_resource.set_consume_value(gameworld_resource_config["consume_value"])

func configure_gameworld_waypoint():
	for gameworld_waypoint in get_tree().get_nodes_in_group("waypoints"):
		var LOAD_PATH = "res://src/GameWorld/GameWorldObjects/Waypoints/"
		var gameworld_waypoint_config = gameworld_object_configurations["waypoints"][gameworld_waypoint.name]

		if gameworld_waypoint_config.has("name"):
			gameworld_waypoint.set_name_to_speech(load(LOAD_PATH + gameworld_waypoint_config["name"]))

func load_inventory():
	inventory = $Inventory
	inventory.load_gameworld_resource_configurations(gameworld_object_configurations['resources'])
	inventory.load_items()

func load_object_configurations():
	var gameworld_object_configurations_data = File.new()
	var file_name = GAMEWORLD_OBJECT_CONFIG_PATH
	if not gameworld_object_configurations_data.file_exists(file_name):
		print("ERROR: could not load %s" % file_name)
		return 
		
	gameworld_object_configurations_data.open(file_name, File.READ)
	gameworld_object_configurations_data = gameworld_object_configurations_data.get_as_text()
	
	gameworld_object_configurations = parse_json(gameworld_object_configurations_data)
	if not typeof(gameworld_object_configurations) == TYPE_DICTIONARY:
		print("ERROR: gameworld_object_definitions parse result invalid; is type " + str(typeof(gameworld_object_configurations)))
		return

	for resource_type in gameworld_object_configurations["resources"].keys():
		gameworld_resource_craft_mappings[resource_type] = gameworld_object_configurations["resources"][resource_type]["craft_mappings"]

func load_waypoints():
	# TODO: load waypoint data from file if appropriate
	
	var gameworld_waypoints_config = gameworld_object_configurations["waypoints"]
	for waypoint in gameworld_waypoints_config:
		var new_waypoint = GameWorldWaypoint.instance()
		new_waypoint.name = waypoint
		# TODO: if loaded waypoint was spawned then set spawn flag, position
		new_waypoint.add_to_group("waypoints")
		add_child(new_waypoint)
		
func on_InventoryMenu_closed():
	if has_node("InventoryMenu"):
		$InventoryMenu.queue_free()
	unpause_game()

func on_MapMenu_closed():
	if has_node("MapMenu"):
		$MapMenu.queue_free()
	unpause_game()

func on_InventoryMenu_item_consumed(consume_value):
	$EnergyLevel.update(consume_value)

func on_MapMenu_waypoint_placed(marker_position):
	# waypoint.translation.x = ($Crosshair.position.x / 1280) * 52 - 30  # TODO
	# waypoint.translation.z = ($Crosshair.position.y /720) * 58 - 36  # TODO
	pass

func on_Obstacle_harvested(obstacle, resource):
	if not inventory.is_at_max_capacity():
		var resource_type = resource.get_type()
		inventory.add_item_from_resource_type(resource_type)
		obstacle.remove_from_group("harvestable")
		resource.queue_free()
		$Map/Player/Pickup.play()
	else:
		$Map/Player/RejectPickup.play()

func open_map_menu():
	# TODO: load tactile map scene and configure data for:
	# player position, waypoint(s), resources
	var map_menu = MapMenu.instance()
	map_menu.connect("closed",self,"on_MapMenu_closed")
	map_menu.connect("waypoint_placed",self,"on_MapMenu_waypoint_placed")
	#map_menu.set_map_dimensions({"x": $GridMap.cell_size.x, "y": $GridMap.cell_size.z})
	add_child(map_menu)
	pause_game()

func open_inventory_menu():
	var inventory_menu = InventoryMenu.instance()
	inventory_menu.load_craft_mappings(gameworld_resource_craft_mappings)
	inventory_menu.load_inventory(inventory)
	inventory_menu.connect("closed",self,"on_InventoryMenu_closed")
	inventory_menu.connect("item_consumed",self,"on_InventoryMenu_item_consumed")
	add_child(inventory_menu)
	pause_game()

func pause_game():
	paused = true
	if $Map/Ambiance.is_playing():
		$Map/Ambiance.stop()
	$Map/Player.paused = true
	if $Map/Player/Footsteps.is_playing():
		$Map/Player/Footsteps.stop()
	
func populate_tactile_map_with_marker_data():
	pass

func unpause_game():
	paused = false
	$Map/Player.paused = false
	if not $Map/Ambiance.is_playing():
		$Map/Ambiance.play()
