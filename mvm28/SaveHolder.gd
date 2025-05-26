extends Button
@export var saveId=0;
var shouldActivate=false;
func _ready():
	if (GlobalSettings.save_exists(saveId)):
		shouldActivate=true;
		text="CanClick"
	else:
		shouldActivate=false;
		text="CannotClick"


func _on_button_down():
	if (shouldActivate):
		GlobalSettings.load_save_file(saveId)
