extends Node3D
@export var target:Node3D;
@export var displacer:Node3D;
@export var maxDisplacement=2;
@export var cam:Camera3D;
const CAMERA_TURN_SPEED=deg_to_rad(180);
var mouseHidden:bool=true;
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
func _physics_process(delta):
	if (target!=null):
		global_position=target.global_position+Vector3.UP;
	if (Globals.paused):
		return;
	var cam_input = Input.get_vector("TurnCameraLeftController","TurnCameraRightController","TurnCameraDownController","TurnCameraUpController");
	if (cam_input!=Vector2.ZERO):
		var cam_target_angle=CAMERA_TURN_SPEED*cam_input.x*delta
		transform.basis=transform.basis.rotated(transform.basis.y,cam_target_angle);
		cam_target_angle=CAMERA_TURN_SPEED*cam_input.y*delta;
		$PitchPivot.transform.basis=$PitchPivot.transform.basis.rotated($PitchPivot.transform.basis.x,cam_target_angle)
		$PitchPivot.rotation_degrees.x=clamp($PitchPivot.rotation_degrees.x,-60,60);
	moveCameraRelative(delta);
func _unhandled_input(event):
	if ((event is InputEventMouseMotion) and mouseHidden):
		rotation_degrees.y-=event.relative.x*0.5;
		$PitchPivot.rotation_degrees.x-=event.relative.y*0.2;
		$PitchPivot.rotation_degrees.x=clamp($PitchPivot.rotation_degrees.x,-60,60);
	elif (Input.is_action_just_pressed("ui_cancel")):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if mouseHidden else Input.MOUSE_MODE_CAPTURED);
		mouseHidden=!mouseHidden;
func moveCameraRelative(delta):
	if ("velocity" in target):
		displacer.global_position=$PitchPivot.global_position+target.velocity.normalized()*maxDisplacement;
		var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
		if (movementVector==Vector2.ZERO):
			displacer.global_position=$PitchPivot.global_position;
		displacer.position.y=0;
		displacer.position.z=0;
		$PitchPivot/SpringArm3D.position.x=move_toward($PitchPivot/SpringArm3D.position.x,displacer.position.x,delta);
		#print($PitchPivot/SpringArm3D.position)
func make_current():
	cam.current=true;
