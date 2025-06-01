class_name InventoryItemSlot extends TextureButton
var itemToShow:Item;
var highlighted:bool=false;
signal was_highlighted(slot);
func setIcon(icon:Texture2D):
	$IconHolder.texture=icon;
func setItem(itemToShow:Item):
	self.itemToShow=itemToShow;
	setIcon(itemToShow.icon);
func process():
	if (highlighted) and Input.is_action_just_pressed("ShoulderLeft"):
		print('yes');


func _on_mouse_entered():
	emit_signal("was_highlighted",self);
	grab_focus();
	pass # Replace with function body.


func _on_focus_entered():
	emit_signal("was_highlighted",self);
	pass # Replace with function body.
