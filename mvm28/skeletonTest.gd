extends Node3D
var skel:Skeleton3D;
var holder;
@export var weapon:Node3D;
func _ready():
	await get_tree().process_frame;
	var skel = $ThirdTestCharacter/Armature/Skeleton3D;
	print(skel);
	var hand = skel.find_bone("Hand.R");
	print(skel.get_bone_pose(hand));
	holder = BoneAttachment3D.new();
	holder.set_bone_idx(hand);
	holder.set_bone_name("Hand.R");
	var xform: Transform3D = skel.get_bone_global_pose(hand)
	holder.global_transform=xform;
	skel.add_child(holder);
	weapon.reparent(holder);
	weapon.position=Vector3.ZERO;
	weapon.rotate(weapon.transform.basis.y,PI)
func _process(delta):
	print(holder.global_position);
	pass;
