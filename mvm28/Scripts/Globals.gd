extends Node
const STANDARD_TERRAIN=0x0;
const SLIPPERY_TERRAIN=0x1;
const GAME_MODE_ACTION=0x0;
const GAME_MODE_MENU=0x1;
const GAME_MODE_CUTSCENE=0x2;

var paused=false;
var gameMode=GAME_MODE_ACTION;
func get_terrain(terrain_name:String):
	match(terrain_name):
		"STANDARD_TERRAIN":
			return STANDARD_TERRAIN;
		"SLIPPERY_TERRAIN":
			return SLIPPERY_TERRAIN;
