class_name EquippableWeapon extends Node3D

@export var referenceItem:WeaponItem;


func use():
	PlayerCharacter.singleton.makeAttack();
