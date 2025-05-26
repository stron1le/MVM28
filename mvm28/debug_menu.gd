extends Panel
var target:CharacterBody3D;

var availableVBoxes:Array[VBoxContainer];
var availableLabels:Array[Label];
var usedLabels:Array[Label];
var horizontalContainer:HBoxContainer;
const MAX_PER_VBOX=5;
var menu_generated:bool=false;
func _ready():
	visible=false;
	target=get_parent() as CharacterBody3D;
	horizontalContainer=$HBoxContainer;
func toggle_debug_menu():
	set_visible(!visible);
	dynamically_generate_menu();
func _process(delta):
	if (Input.is_action_just_pressed("Debug")):
		toggle_debug_menu();
	if (visible and target!=null):
		for label in availableLabels:
			label.text=label.get_meta("propertyName")+": "+str(label.get_meta("propertyFunction").call())
func dynamically_generate_menu():
	if (menu_generated):
		return;
	var root = get_tree().get_root();
	if (target.has_method("get_debug_properties")):
		var propertiesDict=target.get_debug_properties();
		var propertiesSize=propertiesDict.size();
		var vBoxesNeeded = propertiesSize/10+(0 if propertiesSize%10==0 else 1);
		for lab in availableLabels:
			lab.reparent(self);
		while (vBoxesNeeded>availableVBoxes.size()):
			var newbox = VBoxContainer.new()
			availableVBoxes.append(newbox);
			$HBoxContainer.add_child(newbox);
		var propertyIndex=0;
		for propkey in propertiesDict:
			var selectLabel;
			if (propertyIndex==availableLabels.size()):
				selectLabel=Label.new();
				selectLabel.text=propkey+": "+str(propertiesDict.get(propkey).call());
				availableLabels.append(selectLabel);
				root.add_child(selectLabel);
			else:
				selectLabel=availableLabels.get(propertyIndex);
			
			selectLabel.set_meta("propertyName",propkey)
			selectLabel.set_meta("propertyFunction",propertiesDict.get(propkey));
			selectLabel.reparent(availableVBoxes.get(propertyIndex/10));
			propertyIndex+=1;
	menu_generated=true;
