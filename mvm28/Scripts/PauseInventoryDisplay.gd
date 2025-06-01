extends HBoxContainer
@export var slotNode:PackedScene;
@export var SelectorNode:Control;
@export var DescLabel:Label;
var highlightedNode;
func _process(delta):
	if (Input.is_action_just_pressed("Pause")):
		updateDisplays();
func updateDisplays():
	for i in get_children():
		i.queue_free();
	var childIndex=0;
	for i in Globals.Inventory:
		var newSlot = slotNode.instantiate();
		add_child(newSlot);
		var asSlot = newSlot as InventoryItemSlot;
		asSlot.setItem(Globals.Inventory.get(i));
		asSlot.connect("was_highlighted",setHighlightedNode)
		if (childIndex==0):
			asSlot.grab_focus();
		childIndex+=1;
	if (childIndex!=0): setHighlightedNode(get_child(0));
func setHighlightedNode(highlightedNode):
	for i in get_children():
		i.highlighted=false;
	self.highlightedNode=highlightedNode
	highlightedNode.highlighted=true;
	SelectorNode.global_position=highlightedNode.global_position;
	SelectorNode.visible=true;
	DescLabel.text=str(highlightedNode.itemToShow.instanceID);
