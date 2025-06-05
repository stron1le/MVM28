class_name InventoryItemSlot extends TextureButton
var itemToShow:Item;
var highlighted:bool=false;
signal was_highlighted(slot);
func setIcon(icon:Texture2D):
	$IconHolder.texture=icon;
func setItem(itemToShow:Item):
	self.itemToShow=itemToShow;
	setIcon(itemToShow.icon);
func _process(delta):
	if (highlighted):
		if (Input.is_action_just_pressed("ShoulderLeft")):
			PlayerCharacter.singleton.ActionItem1=itemToShow;
			PlayerCharacter.singleton.actionItemChange.emit();
		elif (Input.is_action_just_pressed("ShoulderRight")):
			PlayerCharacter.singleton.ActionItem2=itemToShow;
			PlayerCharacter.singleton.actionItemChange.emit();
		elif (Input.is_action_just_pressed("TriggerLeft")):
			PlayerCharacter.singleton.ActionItem3=itemToShow;
			PlayerCharacter.singleton.actionItemChange.emit();
		elif (Input.is_action_just_pressed("TriggerRight")):
			PlayerCharacter.singleton.ActionItem4=itemToShow;
			PlayerCharacter.singleton.actionItemChange.emit();
func _on_mouse_entered():
	emit_signal("was_highlighted",self);
	grab_focus();
	pass # Replace with function body.


func _on_focus_entered():
	emit_signal("was_highlighted",self);
	pass # Replace with function body.
