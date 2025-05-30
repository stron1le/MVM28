extends Node

var currentGame:int=0;
var continueGame:bool = false;
const SETTINGS_STRING="user://MVM28_Global_Settings.txt";
func _ready():
	load_global_settings();
func load_global_settings():
	var settingsContent;
	if (FileAccess.file_exists(SETTINGS_STRING)):
		var readFile=FileAccess.open(SETTINGS_STRING,FileAccess.READ);
		if (readFile.get_as_text()=="null"):
			settingsContent={};
		else:
			settingsContent = DeJSON(readFile.get_as_text());
		readFile.close();
	else:
		settingsContent={};
	parseSettingInfo(settingsContent);
func parseSettingInfo(settingsContent):
	for k in settingsContent:
		match(k):
			"continueGame":
				continueGame=settingsContent.get(k) as bool;
			"currentGame":
				currentGame=settingsContent.get(k) as int;
			_:
				pass;
func save_exists(file:int):
	return FileAccess.file_exists("user://Save"+str(file)+".txt");
func save():
	var filePath="user://Save"+str(currentGame)+".txt";
	var saveFile=FileAccess.open(filePath,FileAccess.WRITE);
	var saveContents=collectSaveContents();
	continueGame=true;
	saveFile.store_string(JSON.stringify(saveContents));
	saveFile.close();
	store_global_settings();
func collectSaveContents():
	var saveDictionary={};
	saveDictionary.set("playerPosition",Globals.playerPosition);
	print(get_tree().current_scene.name);
	saveDictionary.set("Scene",get_tree().current_scene.name)
	saveDictionary.set("Inventory",Globals.getInventoryDictionary());
	return saveDictionary;
func DeJSON(jsonstring):
	var json=JSON.new();
	var contents = json.parse_string(jsonstring);
	contents = contents as Dictionary;
	return contents;

func store_global_settings():
	var clearFile=FileAccess.open(SETTINGS_STRING,FileAccess.WRITE);
	var settingDictionary = {};
	settingDictionary.set("continueGame",continueGame);
	settingDictionary.set("currentGame",currentGame);
	var jsonDictionary = JSON.stringify(settingDictionary);
	clearFile.store_string(jsonDictionary);
func load_save_file(file:int):
	if (save_exists(file)):
		var jsoncontents = FileAccess.open("user://Save"+str(file)+".txt",FileAccess.READ).get_as_text();
		if (jsoncontents==""):
			jsoncontents="{}";
		var contents=JSON.parse_string(jsoncontents) as Dictionary;
		if (contents.has("playerPosition")):
			Globals.playerPosition=contents.get("playerPosition");
		if (contents.has("Inventory")):
			print(contents.get("Inventory"));
			var invenDict=contents.get("Inventory");
			for i in invenDict:
				var itemDict = invenDict.get(i);
				var newItem = Item.new();
				newItem.populateFromDict(itemDict);
				print(newItem.name);
				Globals.add_to_Inventory(newItem);
		if (contents.has("Scene")):
			loadGameScene(contents.get("Scene"));
func get_first_available_slot():
	var foundSlot=-1;
	for i in range(20):
		if (!save_exists(i)):
			foundSlot=i;
			break;
	return foundSlot;
func loadGameScene(scene):
	sceneCheck(scene);
	get_tree().change_scene_to_file("res://Scenes/"+scene+".tscn");
func sceneCheck(scene):
	match(scene):
		"test_room":
			return scene;
		_:
			push_error("UNALLOWED SCENE: "+scene);
			return "test_room";
