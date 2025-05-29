extends Resource
class_name Item;
@export var ID:int;
@export var name:String;
@export var duplicatesAllowed=true;
@export var usableNode:PackedScene;
@export var itemType:ITEMTYPES;
@export var itemUseType:ITEMUSEEFFECT
enum ITEMUSEEFFECT {HEAL1,DAMAGE1}
enum ITEMTYPES {KEY,KEYUSABLE,CONSUMABLE,WEAPON,VISAGE};
func use():
	if (itemType!=ITEMTYPES.CONSUMABLE):
		return;
	match(itemUseType):
		ITEMUSEEFFECT.HEAL1:
			PlayerCharacter.singleton.HPChanged(1);
		ITEMUSEEFFECT.DAMAGE1:
			PlayerCharacter.singleton.HPChanged(-1);
	print("Used "+name);
	pass;
func equip():
	print("Equipped "+name);
	pass;
func get_quantity():
	return 
