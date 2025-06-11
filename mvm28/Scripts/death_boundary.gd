extends Area3D

func reset():
	Globals.load_level();


func _on_body_entered(body):
	call_deferred("reset");
	pass # Replace with function body.
