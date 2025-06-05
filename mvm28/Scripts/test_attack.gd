extends Area3D
signal hitObject;
func _process(delta):
	if (Globals.paused):
		$Timer.paused=true;
	else:
		$Timer.paused=false;
func _on_body_entered(body):
	var x = body as Node3D;
	if (x.is_in_group("Enemy")):
		emit_signal("hitObject",body);
		print("enteredbody");
		
	pass # Replace with function body.


func _on_hit_object(body):
	if (PlayerCharacter.singleton.currentState==PlayerCharacter.PLAYERSTATE.ACT_JUMP):
		PlayerCharacter.singleton.velocity.y=8;
		PlayerCharacter.singleton.currentState=PlayerCharacter.PLAYERSTATE.ACT_JUMP;
	if ("health" in body):
		body.health-=1;
	pass # Replace with function body.


func _on_timer_timeout():
	queue_free();
	pass # Replace with function body.
