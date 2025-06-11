extends Node3D
var rayc:RayCast3D;
var points=[];
var timeLaps;
func _ready():
	rayc=RayCast3D.new();
	add_child(rayc);
	rayc.target_position=Vector3.UP*-200
	
func _physics_process(delta):
	points=[];
	for i in range(20):
		for j in range(100):
			rayc.position=Vector3(i,0,j);
			rayc.force_raycast_update();
			if (rayc.is_colliding()):
				points.append(rayc.get_collision_point());
