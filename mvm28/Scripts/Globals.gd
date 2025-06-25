extends Node
const STANDARD_TERRAIN = 0x0;
const SLIPPERY_TERRAIN = 0x1;
const GAME_MODE_ACTION = 0x0;
const GAME_MODE_MENU = 0x1;
const GAME_MODE_CUTSCENE = 0x2;

var paused = false;
var playerPosition = -1;
var gameMode = GAME_MODE_ACTION;
var spawnLocations = {};
var Inventory = {};
var openedChests = [];
var currentLevel:String = "test_room"


func _process(delta):
	if (Input.is_action_just_pressed("TriggerRight") and not paused):
		add_test_weapon();


func add_test_weapon():
	var x = load("res://Items/WeaponItem/default_weapon.tres").duplicate();
	add_to_Inventory(x);


func get_terrain(terrain_name:String):
	match(terrain_name):
		"STANDARD_TERRAIN":
			return STANDARD_TERRAIN;
		"SLIPPERY_TERRAIN":
			return SLIPPERY_TERRAIN;


func getInventoryDictionary():
	var newDict = {};
	for k in Inventory.keys():
		var itemToString = Inventory.get(k);
		newDict.get_or_add(k,itemToString.convertToDictionary());
	return newDict;


func add_to_Inventory(newItem:Item,ignoreRecreateForWeapon = false):
	if (newItem is WeaponItem):
		if (not ignoreRecreateForWeapon):
			while(Inventory.has(newItem.instanceID)):
				newItem.generate_random_ID();
		Inventory.get_or_add(newItem.instanceID,newItem);
		return;
	if (newItem.stackable):
		var added:bool = false;
		var itemID = newItem.ID;
		for i in Inventory:
			if itemID == Inventory.get(i).ID and not added:
				Inventory.get(i).quantity += newItem.quantity;
				added = true;
		if (added):
			return;
		else:
			if (newItem.recreateID):
				while(Inventory.has(newItem.instanceID)):
					newItem.generate_random_ID();
			Inventory.get_or_add(newItem.instanceID,newItem);
			return;
	if (newItem.recreateID):
		while (Inventory.has(newItem.instanceID)):
			newItem.generate_random_ID();
	Inventory.get_or_add(newItem.instanceID,newItem);


func _ready():
	pass;


func load_level():
	get_tree().call_group("DestroyOnLoad","queue_free");
	get_tree().change_scene_to_file("res://Scenes/" + currentLevel + ".tscn");
