extends CharacterBody3D
const MAX_RUN_SPEED=5;
const RUN_ACCELERATION=5;
const RUN_DECAY=15;
const MAX_TURN_SPEED_DEGREES=360;
const MAX_TURN_SPEED=deg_to_rad(MAX_TURN_SPEED_DEGREES);
var prevAngle;
var forwardVel:float=0;
func _physics_process(delta):
	var movementVector = Input.get_vector("HorizontalAxisNegative","HorizontalAxisPositive","ForwardAxisNegative","ForwardAxisPositive");
	var intendedMagnitude=movementVector.length();
	if (movementVector!=Vector2.ZERO):
		var forwardVec = transform.basis.z;
		forwardVec.y=0;
		var movementVector3D = Vector3(movementVector.x,0,movementVector.y)
		var targetAngle=forwardVec.signed_angle_to(movementVector3D,transform.basis.y);
		if (abs(targetAngle)>MAX_TURN_SPEED*delta):
			targetAngle=sign(targetAngle)*MAX_TURN_SPEED*delta;
		transform.basis=transform.basis.rotated(transform.basis.y,targetAngle);
		if (prevAngle!=null):
			pass;
			#print(targetAngle-prevAngle);
		prevAngle=targetAngle;
	forwardVel=move_toward(forwardVel,MAX_RUN_SPEED*intendedMagnitude,RUN_ACCELERATION*delta)
	velocity=transform.basis.z*forwardVel;
	print(forwardVel);
	move_and_slide();
