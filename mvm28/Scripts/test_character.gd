class_name PlayerCharacter extends CharacterBody3D
#GlitchesToFix
#TODO: platforms don't pause with global.paused
#TODO: Consider whether using velocity to measure if you should grab is wise.
#TODO: Fix issues with ledge grab on slopped surfaces

const INITIAL_JUMP_SPEED = 10;
const RUNNING_JUMP_MULTIPLIER = 0.0;
const MAX_RUN_SPEED = 10;
const MAX_GREATSWORD_WALK_SPEED = 3;
const RUN_ACCELERATION = 20;
const BRAKE_ACCELERATION = 20;
const BRAKE_RANGE = PI*0.77
const RUN_DECAY = 15;
const MAX_TURN_SPEED_DEGREES = 720;
const COYOTE_TIME_FRAMES = 5;
const MAX_TURN_SPEED = deg_to_rad(MAX_TURN_SPEED_DEGREES);
const MAX_DASH_TURN_SPEED = deg_to_rad(90);
const BRAKE_JUMP_SPEEDS = Vector2(20,10)
const CUT_JUMP_MULTIPLIER = 0.5;
const STANDARD_DRAG = 0.35;
const STRAIN_FORWARD_FACTOR = 20;
const DRAG_EXCESS_FORWARD_FACTOR = 1.0;
const DRAG_EXCESS_BACKWARD_FACTOR = 2.0;
const DASH_SPEED = 15;


enum PLAYERSTATE {
	ACT_STANDING = 0x0, 
	ACT_WALKING = 0x1, 
	ACT_RUNNING = 0x2, 
	ACT_BRAKING = 0x3,
	ACT_JUMP = 0x4,
	ACT_GREATSWORD_WALK,
	ACT_GREATSWORD_SWING,
	ACT_TEST,ACT_DASHING,
	ACT_LEDGE_GRAB,
}


@export var currentState:PLAYERSTATE = PLAYERSTATE.ACT_STANDING;
@export var forwardVel:float = 0.0;
@export var dashTimer:Timer;
@export var rightHand:Node3D;
@export var ledgeGrabbedObject:Node3D;


var prevAngle;
var swingAftermathTimer:float = 0.0;
var slideX = 0.0;
var slideZ = 0.0;
var coyote_timer = -1;
var canCutJump:bool = false;
var maxHP = 30;
var HP = 30;
var ledgeGrabbedPrevPosition:Vector3;
var shapeCastReporter;
var grabHeightReporter;
var ledgeLetGo:bool = false;
var addVelOnLetGo:bool = true;
var movementVector2D:Vector2;
var movementVector3D:Vector3;
var forwardShapeCast:ShapeCast3D;
var aboveForwardShapeCast:ShapeCast3D;
var downwardCast:RayCast3D;
static var singleton;
static var ActionItem1:Item;
static var ActionItem2:Item;
static var ActionItem3:Item;
static var ActionItem4:Item;


signal HPAdjust;
signal actionItemChange;


func _ready():
	if (not ledgeGrabbedObject):
		ledgeGrabbedObject = Node3D.new();
	singleton = self;
	await get_tree().physics_frame
	shapeCastReporter = $ShapeCastResultReporter
	(shapeCastReporter).reparent(get_tree().root);
	forwardShapeCast = $ForwardShapeCast as ShapeCast3D;
	aboveForwardShapeCast = $ForwardAboveCast as ShapeCast3D;
	downwardCast=$DownwardCast as RayCast3D;

func HPChanged(amount):
	HP += amount;
	HP = clamp(HP,0,maxHP)
	HPAdjust.emit();


func _process(delta):
	if (Input.is_action_just_pressed("Pause")):
		Globals.paused = not Globals.paused;
		$PauseMenu.visible = not $PauseMenu.visible;
	if (Input.is_action_just_pressed("Attack")):
		makeAttack();
	movementVector2D=get_controller_movement_axes()

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
			print("There is no such state " + str(currentState))
			act_walking(delta);


func act_walking(delta):
	var intendedMagnitude = movementVector2D.length();
	var forwardVec = get_horizontal_forward();
	var movementVector3D = Vector3(movementVector2D.x,0,movementVector2D.y)
	movementVector3D = movementVector3D.rotated(transform.basis.y,get_camera_yaw());
	var shouldRotate:bool = true;
	if (movementVector2D != Vector2.ZERO):
		var targetAngle = forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		if (abs(targetAngle) >= (BRAKE_RANGE) and forwardVel>2):
			currentState = PLAYERSTATE.ACT_BRAKING;
			intendedMagnitude = 0;
			shouldRotate = false;
		elif (abs(targetAngle)>MAX_TURN_SPEED*delta):
			targetAngle = sign(targetAngle)*MAX_TURN_SPEED*delta;
		if (shouldRotate):
			transform.basis = transform.basis.rotated(transform.basis.y,targetAngle);
			prevAngle = targetAngle;
	forwardVel = move_toward(forwardVel,MAX_RUN_SPEED*intendedMagnitude,RUN_ACCELERATION*delta)
	velocity = transform.basis.z*forwardVel;
	if (forwardVel == 0):
		currentState = PLAYERSTATE.ACT_STANDING;
	move_and_slide();
	coyoteTimerSteps();
	enter_greatsword_check();
	check_common_exits();
	return true;


func act_standing(delta):
	var intendedMagnitude = movementVector2D.length();
	if (movementVector2D != Vector2.ZERO):
		var forwardVec = get_horizontal_forward();
		var movementVector3D = Vector3(movementVector2D.x,0,movementVector2D.y).normalized();
		movementVector3D = movementVector3D.rotated(transform.basis.y,get_camera_yaw());
		var targetAngle = forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		transform.basis = transform.basis.rotated(transform.basis.y,targetAngle);
		prevAngle = targetAngle;
	forwardVel = move_toward(forwardVel,MAX_RUN_SPEED*intendedMagnitude,RUN_ACCELERATION*delta)	
	velocity = transform.basis.z*forwardVel;
	move_and_slide();
	if (forwardVel != 0):
		currentState = PLAYERSTATE.ACT_WALKING;
	coyoteTimerSteps();
	enter_greatsword_check();
	check_common_exits();
	return true;


func act_braking(delta):
	forwardVel = move_toward(forwardVel,0,BRAKE_ACCELERATION*delta);
	velocity = transform.basis.z*forwardVel;
	move_and_slide();
	if (forwardVel == 0):
		currentState = PLAYERSTATE.ACT_STANDING;
	check_common_exits();


func check_common_exits():
	var intendedMagnitude = movementVector2D.length();
	var brakeCheck=currentState == PLAYERSTATE.ACT_BRAKING;
	var movementVector3D = Vector3(movementVector2D.x,0,movementVector2D.y);
	movementVector3D = movementVector3D.rotated(transform.basis.y,get_camera_yaw());
	if (Input.is_action_just_pressed("Jump")):
		velocity.y = (BRAKE_JUMP_SPEEDS.y if (brakeCheck) 
				else calculate_Yspeed_based_on_horizontal_speed(INITIAL_JUMP_SPEED,RUNNING_JUMP_MULTIPLIER));
		if (brakeCheck):
			if (intendedMagnitude==0):
				velocity = transform.basis.z*BRAKE_JUMP_SPEEDS.x + velocity.y*transform.basis.y;
			else:
				velocity = movementVector3D.normalized()*BRAKE_JUMP_SPEEDS.x + velocity.y*transform.basis.y;
		currentState = PLAYERSTATE.ACT_JUMP;
		canCutJump = true;
		return true;
	return false;


func calculate_Yspeed_based_on_horizontal_speed(initialSpeed,multiplier):
	return initialSpeed + multiplier*forwardVel;


func act_jump(delta):
	var intendedMagnitude = movementVector2D.length();
	if (canCutJump and not Input.is_action_pressed("Jump") and velocity.y>0):
		velocity.y *= CUT_JUMP_MULTIPLIER;
		canCutJump = false;
	velocity += get_gravity()*delta;
	aerialAdjustment(delta);
	move_and_slide();
	
	if (is_on_floor()):
		canCutJump = false;
		currentState = (PLAYERSTATE.ACT_STANDING if intendedMagnitude == 0 
				else PLAYERSTATE.ACT_WALKING);
	aboveForwardShapeCast.force_shapecast_update();
	forwardShapeCast.force_shapecast_update();
	var shapecastsSatisfied:bool = (!aboveForwardShapeCast.is_colliding() and forwardShapeCast.is_colliding());
	
	var wallcheck = $Wallcheck as ShapeCast3D;
	wallcheck.force_shapecast_update();
	
	if (wallcheck.is_colliding() and velocity.y<0 and shapecastsSatisfied):
		var wallNorm=wallcheck.get_collision_normal(0);
		wallNorm.y=0;
		look_at(global_position+wallNorm);
		downwardCast.global_position.x=wallcheck.get_collision_point(0).x+transform.basis.z.x*.1;
		downwardCast.global_position.z=wallcheck.get_collision_point(0).z+transform.basis.z.z*.1;
		downwardCast.force_raycast_update();
		var prevPosition=global_position
		global_position.y=downwardCast.get_collision_point().y-2;
		$GroundCheck.force_shapecast_update();
		if ($GroundCheck.is_colliding()):
			global_position=prevPosition;
			print('hit');
		else:
			currentState=PLAYERSTATE.ACT_LEDGE_GRAB;
			canCutJump=false;
			var hitObject = downwardCast.get_collider();
			if (ledgeGrabbedObject.get_parent()):
				ledgeGrabbedObject.reparent(hitObject);
			else:
				hitObject.add_child(ledgeGrabbedObject)
			ledgeGrabbedObject.global_position=global_position;
			ledgeGrabbedObject.global_basis=global_basis;
func act_greatsword_walk(delta):
	var intendedMagnitude = movementVector2D.length();
	if (movementVector2D != Vector2.ZERO):
		var forwardVec = get_horizontal_forward();
		var movementVector3D = Vector3(movementVector2D.x,0,movementVector2D.y).normalized();
		var targetAngle = forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		transform.basis = transform.basis.rotated(transform.basis.y,targetAngle);
		prevAngle = targetAngle;
	forwardVel = move_toward(forwardVel,MAX_GREATSWORD_WALK_SPEED*intendedMagnitude,RUN_ACCELERATION*delta)	
	velocity = transform.basis.z*forwardVel;
	move_and_slide();
	if (Input.is_action_just_released("BButtonCharge")):
		currentState = PLAYERSTATE.ACT_GREATSWORD_SWING;
		swingAftermathTimer = 2;
	return true;


func act_greatsword_swing(delta):
	swingAftermathTimer = move_toward(swingAftermathTimer,0,delta);
	if (swingAftermathTimer <= 0):
		if (forwardVel == 0):
			currentState = PLAYERSTATE.ACT_WALKING
		else:
			currentState = PLAYERSTATE.ACT_STANDING;
	move_and_slide();


func act_dashing(delta):
	if (movementVector2D != Vector2.ZERO):
		var forwardVec = get_horizontal_forward();
		var movementVector3D = Vector3(movementVector2D.x,0,movementVector2D.y).rotated(transform.basis.y,get_camera_yaw());
		var targetAngle = forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		targetAngle = min(MAX_DASH_TURN_SPEED*delta,abs(targetAngle))*sign(targetAngle);
		transform.basis = transform.basis.rotated(transform.basis.y,targetAngle);
		prevAngle = targetAngle;
	forwardVel = DASH_SPEED;
	velocity = transform.basis.z*forwardVel;
	move_and_slide();
	coyoteTimerSteps();
	if (Input.is_action_just_pressed("Jump")):
		currentState = PLAYERSTATE.ACT_JUMP;
		velocity.y = INITIAL_JUMP_SPEED;
		dashTimer.stop();


func exit_dash():
	currentState = PLAYERSTATE.ACT_WALKING;


func get_state_name():
	return PLAYERSTATE.keys()[currentState]


func enter_greatsword_check():
	return;
	if (Input.is_action_just_pressed("BButtonCharge")):
		currentState = PLAYERSTATE.ACT_GREATSWORD_WALK


func get_camera_yaw():
	return deg_to_rad(get_viewport().get_camera_3d().global_rotation_degrees.y);


func get_weapon_item():
	if (rightHand and rightHand.get_child_count() != 0):
		return (rightHand.get_child(0) as EquippableWeapon).referenceItem;


func unequip():
	if (rightHand and rightHand.get_child_count() != 0):
		var weap = rightHand.get_child(0);
		weap.queue_free();


func coyoteTimerSteps():
	if (is_on_floor()):
		coyote_timer = -1;
	elif (coyote_timer == -1):
		coyote_timer = COYOTE_TIME_FRAMES;
	else:
		coyote_timer -= 1;
		if (coyote_timer == 0):
			currentState = PLAYERSTATE.ACT_JUMP;
			dashTimer.stop();


func aerialAdjustment(delta):
	var dragThreshold;
	var sidewaysSpeed=0;
	var intendedYawDiff;
	var intendedMagnitude;
	forwardVel=move_toward(forwardVel,0,3.5*delta);
	intendedYawDiff=0
	match(currentState):
		PLAYERSTATE.ACT_JUMP:
			dragThreshold = MAX_RUN_SPEED;
		_:
			dragThreshold = MAX_RUN_SPEED*1.5;
	forwardVel = move_toward(forwardVel,0,delta*STANDARD_DRAG);
	if (movementVector2D!=Vector2.ZERO):
		var movementVector3D = Vector3(movementVector2D.x,0,movementVector2D.y).rotated(transform.basis.y,get_camera_yaw());
		intendedYawDiff = transform.basis.z.signed_angle_to(movementVector3D,transform.basis.y);
		intendedMagnitude=movementVector2D.length();
		var addedForward=STRAIN_FORWARD_FACTOR*cos(intendedYawDiff)*delta*intendedMagnitude;
		
		#print(cos(intendedYawDiff));
		forwardVel += STRAIN_FORWARD_FACTOR*cos(intendedYawDiff)*delta*intendedMagnitude;
		
		sidewaysSpeed = intendedMagnitude * sin(intendedYawDiff) * 300.0 *delta;
		
	if (forwardVel>dragThreshold):
		forwardVel -= 10*delta;
	if (forwardVel<-16):
		print('yes');
		forwardVel += 10*delta;
	var magVector = forwardVel*transform.basis.z;
	velocity = Vector3(magVector.x,velocity.y,magVector.z);
	#print(sin(deg_to_rad(global_rotation_degrees.y+90)+get_camera_yaw()));
	velocity+=transform.basis.x*sidewaysSpeed;
	slideX=velocity.x;
	slideZ=velocity.z;
func act_test(delta):
	var movementVector3D = Vector3(movementVector2D.x,0,movementVector2D.y).rotated(transform.basis.y,get_camera_yaw());


func act_test_jump_momentum(delta):
	var dragThreshold
	var intendedYawDiff;
	var intendedMagnitude;
	match(currentState):
		PLAYERSTATE.ACT_TEST:
			dragThreshold = MAX_RUN_SPEED;
		_:
			dragThreshold = MAX_RUN_SPEED*1.5;
	forwardVel = move_toward(forwardVel,0,delta*STANDARD_DRAG);
	var movementVector3D = Vector3(movementVector2D.x,0,movementVector2D.y).rotated(transform.basis.y,get_camera_yaw());
	if (movementVector2D != Vector2.ZERO):
		intendedYawDiff = transform.basis.z.signed_angle_to(movementVector3D,transform.basis.y);
		intendedMagnitude = movementVector3D.length();
		forwardVel += (STRAIN_FORWARD_FACTOR*cos(intendedYawDiff)*intendedMagnitude*delta);
		var rotationComp = sin(intendedYawDiff)*intendedMagnitude;
	#transform.basis = transform.basis.rotated(transform.basis.y,PI*delta);


func get_debug_properties():
	var propertiesDict = {
		"ForwardVel":func():return forwardVel,
		"Velocity":func():return velocity, 
		"Current State":func():return get_state_name(),
		"ForwardVel2":func():return forwardVel,
		"ForwardVel3":func():return forwardVel,
		"ForwardVel4":func():return forwardVel,
		"ForwardVel5":func():return forwardVel,
		"ForwardVel6":func():return forwardVel,
		"ForwardVel7":func():return forwardVel,
		"ForwardVel8":func():return forwardVel,
		"ForwardVel9":func():return forwardVel
	}
	return propertiesDict;


func makeAttack():
	var newAttackScene = load("res://Scenes/test_attack.tscn") as PackedScene;
	var newAttack = newAttackScene.instantiate();
	get_tree().root.add_child(newAttack);
	newAttack.global_position = global_position + 0.5*$CollisionShape3D.shape.height*transform.basis.y;


func _on_dash_timer_timeout():
	exit_dash()
	pass # Replace with function body.


func _exit_tree():
	print('destroyed');
	
	
func act_ledge_grab(delta):
	velocity = Vector3.ZERO;
	forwardVel = 0;
	var movementVector3D = Vector3(movementVector2D.x,0,movementVector2D.y).rotated(transform.basis.y,get_camera_yaw());
	ledgeLetGo = ledgeLetGo or movementVector2D.length()<0.8;
	var intendedYawDiff = transform.basis.z.signed_angle_to(movementVector3D,transform.basis.y);
	var addedVel = ledgeGrabbedObject.global_position-ledgeGrabbedPrevPosition
	ledgeGrabbedPrevPosition = ledgeGrabbedObject.global_position;
	var newForward=-ledgeGrabbedObject.transform.basis.z.normalized();
	newForward.y=0;
	look_at(position+newForward);
	global_position = ledgeGrabbedObject.global_position;
	if (movementVector2D != Vector2.ZERO):
		if (abs(intendedYawDiff)>PI/2.0 and ledgeLetGo):
			currentState = PLAYERSTATE.ACT_JUMP;
			ledgeLetGo=false;
			if (addVelOnLetGo):
				velocity += addedVel/delta;
		elif (ledgeLetGo and movementVector2D.length()>0.8):
			currentState = PLAYERSTATE.ACT_JUMP;
			velocity.y = 10;
			ledgeLetGo=false;
			if (addVelOnLetGo):
				velocity += addedVel/delta;
		return;


func get_controller_movement_axes():
	return Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive",
			"ForwardAxisNegative","ForwardAxisPositive");


func get_horizontal_forward():
	var forVec = transform.basis.z;
	forVec.y=0;
	return forVec;


func ledge_check():
	if (velocity.y>0):
		return;
	forwardShapeCast.force_shapecast_update();
	aboveForwardShapeCast.force_shapecast_update();
	if (forwardShapeCast.is_colliding() and not aboveForwardShapeCast.is_colliding()):
		move_and_collide(forwardShapeCast.target_position.length()*(transform.basis.z));
		var wallNorm = forwardShapeCast.collision_result[0].normal*-1;
		var forwardVec = get_horizontal_forward()
		wallNorm = Vector3(wallNorm.x,0,wallNorm.z).normalized();
		var targetAngle = forwardVec.signed_angle_to(wallNorm,transform.basis.y);
		transform.basis = transform.basis.rotated(transform.basis.y,targetAngle);
		downwardCast.force_raycast_update();
		if (downwardCast.is_colliding()):
			var hitObject = downwardCast.get_collider();
			global_position.y = downwardCast.get_collision_point().y-2;
			canCutJump = false;
			currentState = PLAYERSTATE.ACT_LEDGE_GRAB;
			if (ledgeGrabbedObject.get_parent()):
				ledgeGrabbedObject.reparent(hitObject);
			else:
				hitObject.add_child(ledgeGrabbedObject)
			ledgeGrabbedObject.global_basis = global_basis;
			ledgeGrabbedObject.global_position = global_position;
			ledgeGrabbedPrevPosition = ledgeGrabbedObject.global_position;
			ledgeLetGo = false;
