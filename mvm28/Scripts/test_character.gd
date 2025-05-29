class_name PlayerCharacter extends CharacterBody3D
const INITIAL_JUMP_SPEED=5;
const RUNNING_JUMP_MULTIPLIER=0.8;
const MAX_RUN_SPEED=10;
const MAX_GREATSWORD_WALK_SPEED=3;
const RUN_ACCELERATION=20;
const BRAKE_ACCELERATION=20;
const BRAKE_RANGE=PI*0.77
const RUN_DECAY=15;
const MAX_TURN_SPEED_DEGREES=720;
const COYOTE_TIME_FRAMES=5;
const MAX_TURN_SPEED=deg_to_rad(MAX_TURN_SPEED_DEGREES);
const BRAKE_JUMP_SPEEDS=Vector2(20,10)
const CUT_JUMP_MULTIPLIER=0.5;
const STANDARD_DRAG=0.35;
const STRAIN_FORWARD_FACTOR=1.5;
const DRAG_EXCESS_FORWARD_FACTOR=1.0;
const DRAG_EXCESS_BACKWARD_FACTOR=2.0;
enum PLAYERSTATE {ACT_STANDING=0x0, ACT_WALKING=0x1, ACT_RUNNING=0x2, ACT_BRAKING=0x3,ACT_JUMP=0x4,ACT_GREATSWORD_WALK,ACT_GREATSWORD_SWING,ACT_TEST}
@export var currentState:PLAYERSTATE=PLAYERSTATE.ACT_STANDING;
var prevAngle;
@export var forwardVel:float=0;
var swingAftermathTimer:float=0;
var slideX=0;
var slideZ=0;
var coyote_timer=-1;
var canCutJump:bool=false;
var maxHP=30;
var HP=30;
signal HPAdjust;
static var singleton;
func _ready():
	singleton=self;
func HPChanged(amount):
	HP+=amount;
	HP=clamp(HP,0,maxHP)
	HPAdjust.emit();
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
		PLAYERSTATE.ACT_GREATSWORD_WALK:
			act_greatsword_walk(delta);
		PLAYERSTATE.ACT_GREATSWORD_SWING:
			act_greatsword_swing(delta);
		PLAYERSTATE.ACT_TEST:
			act_test(delta);
		_:
			print("There is no such state "+str(currentState))
			act_walking(delta);
	#print(currentState);
func act_walking(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var intendedMagnitude=movementVector.length();
	var forwardVec = transform.basis.z;
	forwardVec.y=0;
	var movementVector3D = Vector3(movementVector.x,0,movementVector.y)
	movementVector3D=movementVector3D.rotated(transform.basis.y,get_camera_yaw());
	var shouldRotate:bool = true;
	if (movementVector!=Vector2.ZERO):
		var targetAngle=forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		if (abs(targetAngle)>=(BRAKE_RANGE)):
			currentState=PLAYERSTATE.ACT_BRAKING;
			intendedMagnitude=0;
			shouldRotate=false;
		elif (abs(targetAngle)>MAX_TURN_SPEED*delta):
			targetAngle=sign(targetAngle)*MAX_TURN_SPEED*delta;
		if (shouldRotate):
			transform.basis=transform.basis.rotated(transform.basis.y,targetAngle);
			prevAngle=targetAngle;
	forwardVel=move_toward(forwardVel,MAX_RUN_SPEED*intendedMagnitude,RUN_ACCELERATION*delta)
	velocity=transform.basis.z*forwardVel;
	if (forwardVel==0):
		currentState=PLAYERSTATE.ACT_STANDING;
	move_and_slide();
	coyoteTimerSteps();
	enter_greatsword_check();
	check_common_exits();
	return true;
func act_standing(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var intendedMagnitude=movementVector.length();
	if (movementVector!=Vector2.ZERO):
		var forwardVec=transform.basis.z;
		var movementVector3D = Vector3(movementVector.x,0,movementVector.y).normalized();
		movementVector3D=movementVector3D.rotated(transform.basis.y,get_camera_yaw());
		var targetAngle=forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		transform.basis=transform.basis.rotated(transform.basis.y,targetAngle);
		prevAngle=targetAngle;
	forwardVel=move_toward(forwardVel,MAX_RUN_SPEED*intendedMagnitude,RUN_ACCELERATION*delta)	
	velocity=transform.basis.z*forwardVel;
	move_and_slide();
	if (forwardVel!=0):
		currentState=PLAYERSTATE.ACT_WALKING;
	coyoteTimerSteps();
	enter_greatsword_check();
	check_common_exits();
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
	movementVector3D=movementVector3D.rotated(transform.basis.y,get_camera_yaw());
	if (Input.is_action_just_pressed("Jump")):
		velocity.y=BRAKE_JUMP_SPEEDS.y if (brakeCheck) else calculate_Yspeed_based_on_horizontal_speed(INITIAL_JUMP_SPEED,RUNNING_JUMP_MULTIPLIER);
		if (brakeCheck):
			if (intendedMagnitude==0):
				velocity=transform.basis.z*BRAKE_JUMP_SPEEDS.x+velocity.y*transform.basis.y;
			else:
				velocity=movementVector3D.normalized()*BRAKE_JUMP_SPEEDS.x+velocity.y*transform.basis.y;
		currentState=PLAYERSTATE.ACT_JUMP;
		canCutJump=true;
		return true;
	return false;
func calculate_Yspeed_based_on_horizontal_speed(initialSpeed,multiplier):
	return initialSpeed+multiplier*forwardVel;
func act_jump(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var intendedMagnitude=movementVector.length();
	if (canCutJump and !Input.is_action_pressed("Jump") and velocity.y>0):
		velocity.y*=CUT_JUMP_MULTIPLIER;
		canCutJump=false;
	velocity+=get_gravity()*delta;
	move_and_slide();
	if (is_on_floor()):
		currentState=PLAYERSTATE.ACT_STANDING if intendedMagnitude==0 else PLAYERSTATE.ACT_WALKING;
func act_greatsword_walk(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var intendedMagnitude=movementVector.length();
	if (movementVector!=Vector2.ZERO):
		var forwardVec=transform.basis.z;
		var movementVector3D = Vector3(movementVector.x,0,movementVector.y).normalized();
		var targetAngle=forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		transform.basis=transform.basis.rotated(transform.basis.y,targetAngle);
		prevAngle=targetAngle;
	forwardVel=move_toward(forwardVel,MAX_GREATSWORD_WALK_SPEED*intendedMagnitude,RUN_ACCELERATION*delta)	
	velocity=transform.basis.z*forwardVel;
	move_and_slide();
	if (Input.is_action_just_released("BButtonCharge")):
		currentState=PLAYERSTATE.ACT_GREATSWORD_SWING;
		swingAftermathTimer=2;
	return true;
func act_greatsword_swing(delta):
	swingAftermathTimer=move_toward(swingAftermathTimer,0,delta);
	if (swingAftermathTimer<=0):
		if (forwardVel==0):
			currentState==PLAYERSTATE.ACT_WALKING
		else:
			currentState=PLAYERSTATE.ACT_STANDING;
	move_and_slide();
func get_state_name():
	return PLAYERSTATE.keys()[currentState]
func enter_greatsword_check():
	if (Input.is_action_just_pressed("BButtonCharge")):
		currentState=PLAYERSTATE.ACT_GREATSWORD_WALK
func get_camera_yaw():
	return deg_to_rad(get_viewport().get_camera_3d().global_rotation_degrees.y);
func coyoteTimerSteps():
	if (is_on_floor()):
		coyote_timer=-1;
	elif (coyote_timer==-1):
		coyote_timer=COYOTE_TIME_FRAMES;
	else:
		coyote_timer-=1;
		if (coyote_timer==0):
			currentState=PLAYERSTATE.ACT_JUMP;
func aerialAdjustment(delta):
	var dragThreshold
	var intendedYawDiff;
	var intendedMagnitude;
	match(currentState):
		PLAYERSTATE.ACT_JUMP:
			dragThreshold=MAX_RUN_SPEED;
		_:
			dragThreshold=MAX_RUN_SPEED*1.5;
	forwardVel=move_toward(forwardVel,0,delta*STANDARD_DRAG);
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var movementVector3D=Vector3(movementVector.x,0,movementVector.y).rotated(transform.basis.y,get_camera_yaw());
	if (movementVector!=Vector2.ZERO):
		intendedYawDiff=transform.basis.z.signed_angle_to(movementVector3D,transform.basis.y);
		intendedMagnitude=movementVector3D.length();
		forwardVel+=STRAIN_FORWARD_FACTOR*cos(intendedYawDiff)*delta*intendedMagnitude;
		transform.basis=transform.basis.rotated(transform.basis.y,PI*sin(intendedYawDiff)*intendedMagnitude*delta)
	if (forwardVel>dragThreshold):
		forwardVel-=1.0*delta;
	if (forwardVel<-16):
		forwardVel+=1.0*delta;
	var magVector=forwardVel*transform.basis.z;
	velocity=Vector3(magVector.x,velocity.y,magVector.z);
	#print(velocity);
func act_test(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var movementVector3D=Vector3(movementVector.x,0,movementVector.y).rotated(transform.basis.y,get_camera_yaw());
func act_test_jump_momentum(delta):
	var dragThreshold
	var intendedYawDiff;
	var intendedMagnitude;
	match(currentState):
		PLAYERSTATE.ACT_TEST:
			dragThreshold=MAX_RUN_SPEED;
		_:
			dragThreshold=MAX_RUN_SPEED*1.5;
	forwardVel=move_toward(forwardVel,0,delta*STANDARD_DRAG);
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var movementVector3D=Vector3(movementVector.x,0,movementVector.y).rotated(transform.basis.y,get_camera_yaw());
	if (movementVector!=Vector2.ZERO):
		intendedYawDiff=transform.basis.z.signed_angle_to(movementVector3D,transform.basis.y);
		intendedMagnitude=movementVector3D.length();
		forwardVel += (STRAIN_FORWARD_FACTOR*cos(intendedYawDiff)*intendedMagnitude*delta);
		var rotationComp=sin(intendedYawDiff)*intendedMagnitude;
		print("");
		print("intendedYawDiff: "+str(intendedYawDiff));
		print("intendedMagnitude: "+str(intendedMagnitude));
		print("rotationComp: "+str(rotationComp));
	#transform.basis=transform.basis.rotated(transform.basis.y,PI*delta);
func get_debug_properties():
	var propertiesDict={"ForwardVel":func():return forwardVel,"Velocity":func():return velocity, "Current State":func():return get_state_name(),"ForwardVel2":func():return forwardVel,"ForwardVel3":func():return forwardVel,"ForwardVel4":func():return forwardVel,"ForwardVel5":func():return forwardVel,"ForwardVel6":func():return forwardVel,"ForwardVel7":func():return forwardVel,"ForwardVel8":func():return forwardVel,"ForwardVel9":func():return forwardVel}
	return propertiesDict;
