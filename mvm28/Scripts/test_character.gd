class_name PlayerCharacter extends CharacterBody3D

const ACT_JUMP=0x4;
const JUMP_SPEED=10;
const MAX_RUN_SPEED=10;
const RUN_ACCELERATION=20;
const BRAKE_ACCELERATION=20;
const BRAKE_RANGE=PI*0.63
const RUN_DECAY=15;
const MAX_TURN_SPEED_DEGREES=720;
const MAX_TURN_SPEED=deg_to_rad(MAX_TURN_SPEED_DEGREES);
const BRAKE_JUMP_SPEEDS=Vector2(20,10)
enum PLAYERSTATE {ACT_STANDING=0x0, ACT_WALKING=0x1, ACT_RUNNING=0x2, ACT_BRAKING=0x3,ACT_JUMP=0x4}
@export var currentState:PLAYERSTATE=PLAYERSTATE.ACT_STANDING;
var prevAngle;
var forwardVel:float=0;
func _process(delta):
	if (Input.is_action_just_pressed("Pause")):
		Globals.paused=!Globals.paused;
		$PauseMenu.visible=!$PauseMenu.visible;
func _physics_process(delta):
	if (Globals.paused):
		return;
	match(currentState):
		PLAYERSTATE.ACT_STANDING:
			act_standing(delta);
		PLAYERSTATE.ACT_WALKING:
			act_walking(delta);
		PLAYERSTATE.ACT_BRAKING:
			act_braking(delta);
		PLAYERSTATE.ACT_JUMP:
			act_jump(delta);
		_:
			act_walking(delta);
	#print(currentState);
func act_walking(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var intendedMagnitude=movementVector.length();
	var forwardVec = transform.basis.z;
	forwardVec.y=0;
	var movementVector3D = Vector3(movementVector.x,0,movementVector.y)
	if (movementVector!=Vector2.ZERO):
		var targetAngle=forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		if (abs(targetAngle)>=(BRAKE_RANGE)):
			currentState=PLAYERSTATE.ACT_BRAKING;
			intendedMagnitude=0;
		elif (abs(targetAngle)>MAX_TURN_SPEED*delta):
			targetAngle=sign(targetAngle)*MAX_TURN_SPEED*delta;
			transform.basis=transform.basis.rotated(transform.basis.y,targetAngle);
			prevAngle=targetAngle;
	forwardVel=move_toward(forwardVel,MAX_RUN_SPEED*intendedMagnitude,RUN_ACCELERATION*delta)	
	velocity=transform.basis.z*forwardVel;
	move_and_slide();
	if (forwardVel==0):
		currentState=PLAYERSTATE.ACT_STANDING;
	check_common_exits();
	return true;
func act_standing(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var intendedMagnitude=movementVector.length();
	if (movementVector!=Vector2.ZERO):
		var forwardVec=transform.basis.z;
		var movementVector3D = Vector3(movementVector.x,0,movementVector.y).normalized();
		var targetAngle=forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		transform.basis=transform.basis.rotated(transform.basis.y,targetAngle);
		prevAngle=targetAngle;
	forwardVel=move_toward(forwardVel,MAX_RUN_SPEED*intendedMagnitude,RUN_ACCELERATION*delta)	
	velocity=transform.basis.z*forwardVel;
	move_and_slide();
	if (forwardVel!=0):
		currentState=PLAYERSTATE.ACT_WALKING;
	return true;
func act_braking(delta):
	forwardVel=move_toward(forwardVel,0,BRAKE_ACCELERATION*delta);
	velocity=transform.basis.z*forwardVel;
	move_and_slide();
	if (forwardVel==0):
		currentState = PLAYERSTATE.ACT_STANDING;
	check_common_exits();
func check_common_exits():
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var intendedMagnitude=movementVector.length();
	var brakeCheck=currentState==PLAYERSTATE.ACT_BRAKING;
	var movementVector3D=Vector3(movementVector.x,0,movementVector.y);
	if (Input.is_action_just_pressed("Jump")):
		velocity.y=BRAKE_JUMP_SPEEDS.y if (brakeCheck) else JUMP_SPEED;
		if (brakeCheck):
			if (intendedMagnitude==0):
				velocity=transform.basis.z*BRAKE_JUMP_SPEEDS.x+velocity.y*transform.basis.y;
			else:
				velocity=movementVector3D.normalized()*BRAKE_JUMP_SPEEDS.x+velocity.y*transform.basis.y;
		currentState=ACT_JUMP;
		return true;
	return false;
	pass;
func act_jump(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var intendedMagnitude=movementVector.length();
	velocity+=get_gravity()*delta;
	move_and_slide();
	if (is_on_floor()):
		currentState=PLAYERSTATE.ACT_STANDING if intendedMagnitude==0 else PLAYERSTATE.ACT_RUNNING;
func get_state_name():
	return PLAYERSTATE.keys()[currentState]
