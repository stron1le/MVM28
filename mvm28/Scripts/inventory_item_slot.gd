class_name InventoryItemSlot extends TextureRect
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
	print("hovered over "+str(itemToShow.instanceID));
	pass # Replace with function body.
