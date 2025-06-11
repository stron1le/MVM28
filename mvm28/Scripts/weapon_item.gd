class_name WeaponItem extends Item

@export var weaponID = 0;
@export var weaponScene:PackedScene;

func use():
	var charac = PlayerCharacter.singleton;
	if (charac.rightHand.get_child_count() != 0):
		var characterWeapon = PlayerCharacter.singleton.get_weapon_item();
		if (characterWeapon == self):
			charac.unequip();
		else:
			charac.unequip();
			var weap = makeWeaponScene();
			charac.rightHand.add_child(weap);
	else:
		var weap = makeWeaponScene();
		charac.rightHand.add_child(weap);

func makeWeaponScene():
	var newWeapon = weaponScene.instantiate() as EquippableWeapon;
	newWeapon.referenceItem = self;
	return newWeapon;
func convertToDictionary(removeRecreateId:bool=false):
	var weaponDict = super.convertToDictionary();
	weaponDict.get_or_add("weaponID",weaponID);
	weaponDict.get_or_add("weaponScene",weaponScene.resource_path);
	return weaponDict;
func populateFromDict(ItemDict):
	super.populateFromDict(ItemDict);
	if (ItemDict.has("weaponID")):
		weaponID = ItemDict.get("weaponID");
	if (ItemDict.has("weaponScene")):
		weaponScene = load(ItemDict.get("weaponScene"));
