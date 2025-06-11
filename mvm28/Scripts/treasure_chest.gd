extends Node3D

@export var chestID:int = 0;
@export var items:Array[Item];

var opened:bool = false;

signal openedChest;


func _ready():
	if (chestID in Globals.openedChests):
		opened = true;


func open():
	for item in items:
		if (item == null):
			continue;
		Globals.add_to_Inventory(item);
		print(item.name);
		print(item.ID);
	print(Globals.Inventory);
	opened = true;
	openedChest.emit();
	Globals.openedChests.append(chestID);


func _on_area_entered(area):
	if (area.is_in_group("canActivateSave") and not opened):
		open();
