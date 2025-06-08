class_name PlayerCharacter extends CharacterBody3D
const INITIAL_JUMP_SPEED=10;
const RUNNING_JUMP_MULTIPLIER=0.0;
const MAX_RUN_SPEED=10;
const MAX_GREATSWORD_WALK_SPEED=3;
const RUN_ACCELERATION=20;
const BRAKE_ACCELERATION=20;
const BRAKE_RANGE=PI*0.77
const RUN_DECAY=15;
const MAX_TURN_SPEED_DEGREES=720;
const COYOTE_TIME_FRAMES=5;
const MAX_TURN_SPEED=deg_to_rad(MAX_TURN_SPEED_DEGREES);
const MAX_DASH_TURN_SPEED=deg_to_rad(90);
const BRAKE_JUMP_SPEEDS=Vector2(20,10)
const CUT_JUMP_MULTIPLIER=0.5;
const STANDARD_DRAG=0.35;
const STRAIN_FORWARD_FACTOR=1.5;
const DRAG_EXCESS_FORWARD_FACTOR=1.0;
const DRAG_EXCESS_BACKWARD_FACTOR=2.0;
const DASH_SPEED=15;
enum PLAYERSTATE {ACT_STANDING=0x0, ACT_WALKING=0x1, ACT_RUNNING=0x2, ACT_BRAKING=0x3,ACT_JUMP=0x4,ACT_GREATSWORD_WALK,ACT_GREATSWORD_SWING,ACT_TEST,ACT_DASHING,ACT_LEDGE_GRAB}
@export var currentState:PLAYERSTATE=PLAYERSTATE.ACT_STANDING;
var prevAngle;
@export var forwardVel:float=0;
@export var dashTimer:Timer;
var swingAftermathTimer:float=0;
var slideX=0;
var slideZ=0;
var coyote_timer=-1;
var canCutJump:bool=false;
var maxHP=30;
var HP=30;
signal HPAdjust;
signal actionItemChange;
static var singleton;
static var ActionItem1:Item;
static var ActionItem2:Item;
static var ActionItem3:Item;
static var ActionItem4:Item;
@export var rightHand:Node3D;

var shapeCastReporter;
var grabHeightReporter;
var ledgeLetGo:bool=false;
func _ready():
	singleton=self;
	await get_tree().physics_frame
	shapeCastReporter=$ShapeCastResultReporter
	(shapeCastReporter).reparent(get_tree().root);
func HPChanged(amount):
	HP+=amount;
	HP=clamp(HP,0,maxHP)
	HPAdjust.emit();
func _process(delta):
	if (Input.is_action_just_pressed("Pause")):
		Globals.paused=!Globals.paused;
		$PauseMenu.visible=!$PauseMenu.visible;
	if (Input.is_action_just_pressed("Attack")):
		makeAttack();
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
		PLAYERSTATE.ACT_DASHING:
			act_dashing(delta);
		PLAYERSTATE.ACT_LEDGE_GRAB:
			act_ledge_grab(delta);
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
	ledge_check();
func ledge_check():
	if (velocity.y>0):
		return;
	var forwardShapeCast=$ForwardShapeCast as ShapeCast3D;
	var aboveForwardShapeCast=$ForwardAboveCast as ShapeCast3D;
	forwardShapeCast.force_shapecast_update();
	aboveForwardShapeCast.force_shapecast_update();
	if (forwardShapeCast.is_colliding() and !aboveForwardShapeCast.is_colliding()):
		move_and_collide(forwardShapeCast.target_position.length()*(transform.basis.z));
		var wallNorm=forwardShapeCast.collision_result[0].normal*-1;
		var forwardVec=transform.basis.z;
		wallNorm = Vector3(wallNorm.x,0,wallNorm.z).normalized();
		var targetAngle=forwardVec.signed_angle_to(wallNorm,transform.basis.y);
		transform.basis=transform.basis.rotated(transform.basis.y,targetAngle);
		$DownwardCast.force_raycast_update();
		if ($DownwardCast.is_colliding()):
			global_position.y=$DownwardCast.get_collision_point().y-2;
			currentState=PLAYERSTATE.ACT_LEDGE_GRAB;
			ledgeLetGo=false;
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
			currentState=PLAYERSTATE.ACT_WALKING
		else:
			currentState=PLAYERSTATE.ACT_STANDING;
	move_and_slide();
func act_dashing(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	if (movementVector!=Vector2.ZERO):
		var forwardVec=transform.basis.z;
		var movementVector3D=Vector3(movementVector.x,0,movementVector.y).rotated(transform.basis.y,get_camera_yaw());
		var targetAngle=forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		targetAngle=min(MAX_DASH_TURN_SPEED*delta,abs(targetAngle))*sign(targetAngle);
		transform.basis=transform.basis.rotated(transform.basis.y,targetAngle);
		prevAngle=targetAngle;
	forwardVel=DASH_SPEED;
	velocity=transform.basis.z*forwardVel;
	move_and_slide();
	coyoteTimerSteps();
	if (Input.is_action_just_pressed("Jump")):
		currentState=PLAYERSTATE.ACT_JUMP;
		velocity.y=INITIAL_JUMP_SPEED;
		dashTimer.stop();
func exit_dash():
	currentState=PLAYERSTATE.ACT_WALKING;
func get_state_name():
	return PLAYERSTATE.keys()[currentState]
func enter_greatsword_check():
	return;
	if (Input.is_action_just_pressed("BButtonCharge")):
		currentState=PLAYERSTATE.ACT_GREATSWORD_WALK
func get_camera_yaw():
	return deg_to_rad(get_viewport().get_camera_3d().global_rotation_degrees.y);
func get_weapon_item():
	if (rightHand and rightHand.get_child_count()!=0):
		return (rightHand.get_child(0) as EquippableWeapon).referenceItem;
func unequip():
	if (rightHand and rightHand.get_child_count()!=0):
		var weap = rightHand.get_child(0);
		weap.queue_free();
func coyoteTimerSteps():
	if (is_on_floor()):
		coyote_timer=-1;
	elif (coyote_timer==-1):
		coyote_timer=COYOTE_TIME_FRAMES;
	else:
		coyote_timer-=1;
		if (coyote_timer==0):
			currentState=PLAYERSTATE.ACT_JUMP;
			dashTimer.stop();
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
func makeAttack():
	var newAttackScene = load("res://Scenes/test_attack.tscn") as PackedScene;
	var newAttack=newAttackScene.instantiate();
	get_tree().root.add_child(newAttack);
	newAttack.global_position=global_position+0.5*$CollisionShape3D.shape.height*transform.basis.y;
func _on_dash_timer_timeout():
	exit_dash()
	pass # Replace with function body.
func _exit_tree():
	print('destroyed');
func act_ledge_grab(delta):
	velocity=Vector3.ZERO;
	forwardVel=0;
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var movementVector3D=Vector3(movementVector.x,0,movementVector.y).rotated(transform.basis.y,get_camera_yaw());
	ledgeLetGo=ledgeLetGo or movementVector.length()<0.8;
	if (movementVector!=Vector2.ZERO):
		var intendedYawDiff=transform.basis.z.signed_angle_to(movementVector3D,transform.basis.y);
		if (abs(intendedYawDiff)>PI/2.0):
			print("letGo");
			currentState=PLAYERSTATE.ACT_JUMP;
		elif (ledgeLetGo and movementVector.length()>0.8):
			currentState=PLAYERSTATE.ACT_JUMP;
			velocity.y=10;
			
