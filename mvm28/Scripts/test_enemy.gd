extends StaticBody3D

var health:float = 10: set = _setHealth;


func _setHealth(newHealth):
	health = newHealth;
	if (health <= 0):
		queue_free();
	print(health);
