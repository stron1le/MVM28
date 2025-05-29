extends Node3D
@export var slots:Array[ChestSlot];
func open():
	for s in slots:
		var item = s.item;
