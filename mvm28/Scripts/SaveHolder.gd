extends Button
@export var saveId=0;
var shouldActivate=false;
func _ready():
	checkClickable()

func _on_button_down():
	GlobalSettings.load_save_file(saveId)
func checkClickable():
	if (GlobalSettings.save_exists(saveId)):
		text="Save "+str(saveId);
		disabled=false;
	else:
		text="No save";
		disabled=true;
func _process(delta):
	if (has_focus() and Input.is_action_just_pressed("Attack")):
		if (GlobalSettings.save_exists(saveId)):
			GlobalSettings.delete_save(saveId);
			checkClickable();
