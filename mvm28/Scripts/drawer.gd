extends Node2D

@export var parent:Node3D;
@export var cam:Camera3D;


func _draw():
	if (not parent or not cam):
		return;
	for x in parent.points:
		draw_circle(get_viewport().get_camera_3d().unproject_position(x),.5,Color.AQUAMARINE)
