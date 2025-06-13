extends Node3D

const CAMERA_TURN_SPEED = deg_to_rad(180);

@export var target:Node3D;
@export var displacer:Node3D;
@export var maxDisplacement = 2;
@export var cam:Camera3D;

var lockTarget;
var mouseHidden:bool = true;
var pitchPivot;
var springArm:SpringArm3D;
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	pitchPivot=$PitchPivot;
	springArm=$PitchPivot/SpringArm3D as SpringArm3D;
func _process(delta):
	if (Input.is_action_just_pressed("Lockon")):
		if (lockTarget):
			removeLock();
		else:
			lockTarget = LockOnTarget.get_closest_lockon();
			if (lockTarget):
				lockTarget.connect("disengageLock",removeLock);


func removeLock():
	lockTarget.disconnect("disengageLock",removeLock);
	lockTarget = null;


func _physics_process(delta):
	if (target != null):
		global_position = target.global_position + Vector3.UP;
	if (Globals.paused):
		return;
	if (lockTarget):
		moveCameraRelative(delta);
		var focusPosition = (lockTarget.global_position + global_position)
		focusPosition.y = global_position.y*2;
		look_at(focusPosition/2,Vector3.UP);
		return;
	var cam_input = Input.get_vector("TurnCameraLeftController","TurnCameraRightController","TurnCameraDownController","TurnCameraUpController");
	if (cam_input != Vector2.ZERO):
		var cam_target_angle = CAMERA_TURN_SPEED*cam_input.x*delta
		transform.basis = transform.basis.rotated(transform.basis.y,cam_target_angle);
		cam_target_angle = CAMERA_TURN_SPEED*cam_input.y*delta;
		pitchPivot.transform.basis = pitchPivot.transform.basis.rotated(pitchPivot.transform.basis.x,cam_target_angle)
		pitchPivot.rotation_degrees.x = clamp(pitchPivot.rotation_degrees.x,-60,60);
	moveCameraRelative(delta);


func _unhandled_input(event):
	if ((event is InputEventMouseMotion) and not Globals.paused and not lockTarget):
		rotation_degrees.y -= event.relative.x*0.5;
		pitchPivot.rotation_degrees.x -= event.relative.y*0.2;
		pitchPivot.rotation_degrees.x = clamp(pitchPivot.rotation_degrees.x,-60,60);
	elif (Input.is_action_just_pressed("ui_cancel")):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if mouseHidden else Input.MOUSE_MODE_CAPTURED);
		mouseHidden = not mouseHidden;


func moveCameraRelative(delta):
	if (target is PlayerCharacter and target.currentState == PlayerCharacter.PLAYERSTATE.ACT_JUMP):
		return;
	if ("velocity" in target):
		displacer.global_position = pitchPivot.global_position + target.velocity.normalized()*maxDisplacement;
		var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
		if (movementVector == Vector2.ZERO):
			displacer.global_position = pitchPivot.global_position;
		displacer.position.y = 0;
		displacer.position.z = 0;
		springArm.position.x = move_toward(springArm.position.x,displacer.position.x,delta);
		#print($PitchPivot/SpringArm3D.position)


func make_current():
	cam.current = true;


func initiateLockOn():
	var lock = LockOnTarget.get_closest_lockon();
	if (lock):
		lockTarget = lock;
