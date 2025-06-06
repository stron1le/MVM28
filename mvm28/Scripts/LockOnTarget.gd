class_name LockOnTarget extends Node3D
static var availableLockOnTargets=[];
var inRange:bool;
var onScreen:bool=false;
const MAX_LOCKON_RANGE=20;
static var activeLockOn;
signal disengageLock;
func _ready():
	await get_tree().physics_frame;
	if ($VisibleOnScreenNotifier3D.is_on_screen()):
		onScreen=true;
func _process(delta):
	if (PlayerCharacter.singleton):
		inRange=((global_position-PlayerCharacter.singleton.global_position).length()<MAX_LOCKON_RANGE);
		isAvailable();
func _on_visible_on_screen_notifier_3d_screen_entered():
	onScreen=true;
	isAvailable();
func _on_visible_on_screen_notifier_3d_screen_exited():
	onScreen=false;
	isAvailable();
func isAvailable():
	if (inRange and onScreen):
		if (!availableLockOnTargets.has(self)):
			availableLockOnTargets.append(self);
	else:
		if (availableLockOnTargets.has(self)):
			var lockIndex=availableLockOnTargets.find(self);
			availableLockOnTargets.remove_at(lockIndex)
			disengageLock.emit();
static func get_closest_lockon():
	var closestLock;
	var currentDistance=INF;
	var request=PlayerCharacter.singleton;
	for i in availableLockOnTargets:
		var distance=(request.global_position-i.global_position).length()
		if (distance<currentDistance):
			closestLock=i;
			currentDistance=distance;
	return closestLock;
func initiateLock(otherNode):
	otherNode.lockTarget=self;
	if (otherNode!=null and otherNode.has_method("removeLock")):
		activeLockOn.connect("disengageLock",otherNode.disengageLock);
func _exit_tree():
	if (availableLockOnTargets.has(self)):
		var lockindex=availableLockOnTargets.find(self);
		availableLockOnTargets.remove_at(lockindex);
