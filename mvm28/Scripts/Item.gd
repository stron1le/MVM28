extends Resource
class_name Item;
@export var ID:int;
@export var instanceID:int;
@export var name:String;
@export var stackable:bool = false;
@export var duplicatesAllowed=true;
@export var itemType:ITEMTYPES;
@export var itemUseType:ITEMUSEEFFECT
@export var quantity:int=1;
@export var recreateID:bool = false;
@export var icon:CompressedTexture2D=load("res://PNGs/GreatswordImage.png");
static var IDIconLibrary={};
	
enum ITEMUSEEFFECT {HEAL1,DAMAGE1,DASH}
enum ITEMTYPES {KEY,KEYUSABLE,CONSUMABLE,WEAPON,VISAGE};
func generate_random_ID():
	var newID = randi();
	self.instanceID=newID;
func use():
	if (itemType!=ITEMTYPES.CONSUMABLE):
		return;
	match(itemUseType):
		ITEMUSEEFFECT.HEAL1:
			PlayerCharacter.singleton.HPChanged(1);
		ITEMUSEEFFECT.DAMAGE1:
			PlayerCharacter.singleton.HPChanged(-1);
		ITEMUSEEFFECT.DASH:
			var player = PlayerCharacter.singleton;
			player.currentState=PlayerCharacter.PLAYERSTATE.ACT_DASHING;
			var timer:Timer = player.dashTimer;
			timer.start();
	print("Used "+name);
func equip():
	print("Equipped "+name);
func convertToDictionary(removeRecreateId:bool=false):
	var ItemDict = {};
	ItemDict.get_or_add("ID",ID);
	ItemDict.get_or_add("instanceID",instanceID);
	ItemDict.get_or_add("name",name);
	ItemDict.get_or_add("duplicatesAllowed",duplicatesAllowed);
	ItemDict.get_or_add("itemType",itemType);
	ItemDict.get_or_add("itemUseType",itemUseType);
	ItemDict.get_or_add("quantity",quantity);
	ItemDict.get_or_add("stackable",stackable);
	ItemDict.get_or_add("recreateID",false if removeRecreateId else recreateID);
	return ItemDict;
func populateFromDict(ItemDict):
	if (ItemDict.has("ID")):
		ID=ItemDict.get("ID");
	if (ItemDict.has("instanceID")):
		instanceID=ItemDict.get("instanceID");
	if (ItemDict.has("name")):
		name=ItemDict.get("name");
	if (ItemDict.has("stackable")):
		stackable=ItemDict.get("stackable");
	if (ItemDict.has("duplicatesAllowed")):
		duplicatesAllowed=ItemDict.get("duplicatesAllowed");
	if (ItemDict.has("itemType")):
		itemType=ItemDict.get("itemType");
	if (ItemDict.has("itemUseType")):
		itemUseType=ItemDict.get("itemUseType");
	if (ItemDict.has("quantity")):
		quantity=ItemDict.get("quantity");
	if (ItemDict.has("recreateID")):
		recreateID=ItemDict.get("recreateID");
	icon=load(getIconByID());
func getIconByID():
	match(ID):
		0:
			return "res://PNGs/PotionImage.png"
		1:
			return "res://PNGs/PoisonImage.png"
		5:
			return "res://PNGs/HammerImage.png"
		_:
			print("No icon found for "+str(ID));
			return "res://PNGs/GreatswordImage.png";
