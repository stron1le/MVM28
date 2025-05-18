extends Panel
var target:CharacterBody3D;
const VELOCITY_LABEL_PREFIX:String = "Velocity: "
const STATE_LABEL_PREFIX:String = "Player State: "
const EQUIPPED_ITEM_LABEL:String = "Equipped Item: "
func _ready():
	visible=false;
	target=get_parent() as CharacterBody3D;
func toggle_debug_menu():
	set_visible(!visible);
func _process(delta):
	if (Input.is_action_just_pressed("Debug")):
		toggle_debug_menu();
	if (visible and target!=null):
		$VelocityLabel.text=VELOCITY_LABEL_PREFIX+str(target.velocity);
		$PlayerStateLabel.text=STATE_LABEL_PREFIX+target.get_state_name();
