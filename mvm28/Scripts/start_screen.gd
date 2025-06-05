class_name startSaveMenu extends Control
var startButton;
var continueButton;
var fileSelectButton;
var quitButton;
const SETTINGS_STRING="user://Global_Settings.txt";
func _ready():
	
	startButton=$MainStart/VBoxContainer/NewGameButton;
	continueButton=$MainStart/VBoxContainer/ContinueButton;
	fileSelectButton=$MainStart/VBoxContainer/FileSelectButton;
	quitButton=$MainStart/VBoxContainer/QuitButton;
	openMainMenu();
	if (GlobalSettings.continueGame):
		continueButton.grab_focus();
	else:
		startButton.grab_focus();
func continueCurrentGame():
	if (GlobalSettings.continueGame):
		GlobalSettings.load_save_file(GlobalSettings.currentGame);
func newGame():
	var nextGame=GlobalSettings.get_first_available_slot();
	if (nextGame==-1):
		return;
	GlobalSettings.currentGame=nextGame;
	Globals.playerPosition=0;
	get_tree().change_scene_to_file("res://Scenes/test_room.tscn");
func quitGame():
	get_tree().quit();

func _on_quit_button_button_down():
	quitGame();


func _on_continue_game_button_button_down():
	continueCurrentGame();


func _on_new_game_button_button_down():
	newGame();
func _on_file_select_button_button_down():
	open_file_select()
func open_file_select():
	$MainStart.visible=false;
	$FileSelectMenu.visible=true;
	$FileSelectMenu/VBoxContainer/SaveHolder.grab_focus();
func openMainMenu():
	$MainStart.visible=true;
	$FileSelectMenu.visible=false;
	fileSelectButton.grab_focus();
func _process(delta):
	if (Input.is_action_just_pressed("ui_cancel")):
		if (!$MainStart.visible):
			openMainMenu();
