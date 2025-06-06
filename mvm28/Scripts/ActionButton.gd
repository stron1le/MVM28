extends TextureRect
@export var currentItem:Item;
@export var mappedButton:BUTTONACKNOWLEDGEMENT;
enum BUTTONACKNOWLEDGEMENT {SHOULDERLEFT=1,SHOULDERRIGHT=2,TRIGGERLEFT=3,TRIGGERRIGHT=4}
func _ready():
	await get_tree().process_frame
	PlayerCharacter.singleton.actionItemChange.connect(updateContents)
	updateContents();
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
func updateContents():
	match(mappedButton):
		BUTTONACKNOWLEDGEMENT.SHOULDERLEFT:
			set_item(PlayerCharacter.ActionItem1);
		BUTTONACKNOWLEDGEMENT.SHOULDERRIGHT:
			set_item(PlayerCharacter.ActionItem2);
		BUTTONACKNOWLEDGEMENT.TRIGGERLEFT:
			set_item(PlayerCharacter.ActionItem3);
		_:
			set_item(PlayerCharacter.ActionItem4);
	if (currentItem): $IconTexture.texture=currentItem.icon;
