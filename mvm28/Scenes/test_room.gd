extends Node3D
func _ready():
	var ap = $AnimationPlayer as AnimationPlayer;
	ap.play("move");
