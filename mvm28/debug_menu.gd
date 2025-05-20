extends Panel
var target:CharacterBody3D;
const VELOCITY_LABEL_PREFIX:String = "Velocity: "
const STATE_LABEL_PREFIX:String = "Player State: "
const EQUIPPED_ITEM_LABEL:String = "Equipped Item: "
var velocity_label;
var player_state_label;
var equipped_item_label;
func _ready():
	visible=false;
	target=get_parent() as CharacterBody3D;
	velocity_label=$VBoxContainer/VelocityLabel;
	player_state_label=$VBoxContainer/PlayerStateLabel;
	equipped_item_label=$VBoxContainer/EquippedItemLabel;
func toggle_debug_menu():
	set_visible(!visible);
func _process(delta):
	if (Input.is_action_just_pressed("Debug")):
		toggle_debug_menu();
	if (visible and target!=null):
		velocity_label.text=VELOCITY_LABEL_PREFIX+str(target.velocity);
		player_state_label.text=STATE_LABEL_PREFIX+target.get_state_name();
