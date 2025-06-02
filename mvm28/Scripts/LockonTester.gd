class_name LockOn extends Node3D
@export var target1:Node3D;
@export var target2:Node3D;
static var availableLockOns=[];
func _process(delta):
	if (target1!=null):
		if (target2!=null):
			global_position=(target1.global_position+target2.global_position)*0.5;
		else:
			global_position=target1.global_position;
	elif (target2!=null):
		global_position=target2.global_position;
func _init():
	availableLockOns.append(self);
func _exit_tree():
	var lockonIndex=availableLockOns.find(self);
	availableLockOns.remove_at(lockonIndex)
