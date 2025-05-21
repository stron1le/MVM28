extends Node3D
@export var target:Node;
const CAMERA_TURN_SPEED=30;
func _physics_process(delta):
	if (target!=null):
		global_position=target.global_position;
	var cam_input = Input.get_vector("TurnCameraLeftController","TurnCameraRightController","TurnCameraDownController","TurnCameraUpController");
	if (cam_input!=Vector2.ZERO):
		var cam_target_angle=CAMERA_TURN_SPEED*cam_input.x*delta
		transform.basis=transform.basis.rotated(transform.basis.y,cam_target_angle);
		cam_target_angle=CAMERA_TURN_SPEED*cam_input.y*delta;
		$PitchPivot.transform.basis=$PitchPivot.transform.basis.rotated(transform.basis.x,cam_target_angle)
	
