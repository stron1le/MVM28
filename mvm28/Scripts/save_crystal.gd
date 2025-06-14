extends Area3D

const scaleTime = 0.5;

var interacting = false;
var currentScale = 0.5;

@export var id = 0
@export var playerCharacter:PackedScene;
@export var camera:PackedScene;
@export var growShrinkCurve:Curve;


func _ready():
	await get_tree().physics_frame
	if (id == Globals.playerPosition or Globals.playerPosition == -1):
		var newPlay = playerCharacter.instantiate();
		var newCam = camera.instantiate();
		get_tree().get_root().add_child(newPlay);
		get_tree().get_root().add_child(newCam);
		newPlay.position = position + transform.basis.z*3;
		newCam.target = newPlay;
		newCam.make_current();
		Globals.playerPosition = id;


func _on_body_entered(body):
	if (body.is_in_group("Player")):
		interacting = true;
	pass # Replace with function body.


func _process(delta):
	if (not interacting):
		return;
	#if (Input.is_action_just_pressed("Attack")):
		#Globals.playerPosition = id;
		#print('crystal hit' + str(id));
		#GlobalSettings.save();


func _physics_process(delta):
	if (currentScale<scaleTime):
		currentScale += delta;
		print(currentScale);
		$CSGBox3D.scale = growShrinkCurve.sample(currentScale/scaleTime)*Vector3(1,1,1);


func _on_body_exited(body):
	if (body.is_in_group("Player")):
		interacting = false;
	pass # Replace with function body.


func testing_code_delete_later(char):
	var lockOn:PackedScene = load("res://Scenes/lockon.tscn");
	var newLock = lockOn.instantiate();
	get_tree().root.add_child(newLock);
	newLock.global_position = global_position;
	newLock.target1 = self;
	newLock.target2 = char;


func _on_area_entered(area):
	if (area.is_in_group("canActivateSave")):
		Globals.playerPosition = id;
		print('crystal hit' + str(id));
		GlobalSettings.save();
		currentScale = 0;
