extends TextureRect
@export var currentItem:Item;
@export var mappedButton:BUTTONACKNOWLEDGEMENT;
enum BUTTONACKNOWLEDGEMENT {SHOULDERLEFT,SHOULDERRIGHT,TRIGGERLEFT}
func _process(delta):
	if (!Globals.paused and currentItem and Input.is_action_just_pressed(inputConvert())):
		currentItem.use();
func inputConvert():
	match(mappedButton):
		BUTTONACKNOWLEDGEMENT.SHOULDERLEFT:
			return "ShoulderLeft";
		BUTTONACKNOWLEDGEMENT.SHOULDERRIGHT:
			return "ShoulderRight";
		BUTTONACKNOWLEDGEMENT.TRIGGERLEFT:
			return "TriggerLeft";
		_:
			return "TriggerRight";
func set_item(item:Item):
	currentItem=item;
