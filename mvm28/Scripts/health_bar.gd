extends ProgressBar

@export var hpText:Label
@export var target:Node3D;


func _ready():
	set_values();


func _on_test_character_hp_adjust():
	set_values()
	pass # Replace with function body.


func set_values():
	max_value = target.maxHP;
	value = target.HP;
	hpText.text = "HP: " + str(value);
