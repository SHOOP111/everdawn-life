class_name FishingSystem
extends RefCounted

const FISH_BY_SEASON := [
	["Silver Minnow", "Moss Carp", "Rain Darter", "Golden Koi"],
	["Sun Perch", "Glassfin", "Ember Trout", "Golden Koi"],
	["Moss Carp", "Moon Eel", "Rain Darter", "Ancient Sturgeon"],
	["Frost Pike", "Glassfin", "Moon Eel", "Ancient Sturgeon"],
]

var casts: int = 0
var caught: int = 0
var best_catch: String = "None"
var collection: Dictionary = {}
var _random_state: int = 77191

func cast(world: WorldGenerator, position: Vector2, facing: Vector2, season: int, weather: String,
		fishing_level: int, inventory: Dictionary) -> Dictionary:
	var target := position + facing * 24.0
	var tile := Vector2i(target / WorldGenerator.TILE)
	if world.biome_at(tile.x, tile.y) > 1:
		return {"success": false, "message": "Cast toward open water."}
	casts += 1
	_random_state = int((_random_state * 1103515245 + casts * 97 + fishing_level * 31) & 0x7fffffff)
	var chance := 0.58 + float(fishing_level) * 0.018
	if weather in ["Rain", "Drizzle", "Storm"]:
		chance += 0.13
	var roll := float(_random_state % 10000) / 10000.0
	if roll > chance:
		return {"success": false, "message": "A ripple, then stillness. Nothing bit."}
	var table: Array = FISH_BY_SEASON[season]
	var rarity_roll := (_random_state / 37) % 100
	var index := 0
	if rarity_roll > 95 and fishing_level >= 5:
		index = 3
	elif rarity_roll > 76:
		index = 2
	elif rarity_roll > 42:
		index = 1
	var fish_name := str(table[index])
	collection[fish_name] = int(collection.get(fish_name, 0)) + 1
	inventory["Fish"] = int(inventory.get("Fish", 0)) + 1
	caught += 1
	best_catch = fish_name if index >= 2 or best_catch == "None" else best_catch
	return {"success": true, "message": "Caught a %s!" % fish_name, "rarity": index, "fish": fish_name}

func to_dict() -> Dictionary:
	return {"casts": casts, "caught": caught, "best_catch": best_catch, "collection": collection, "state": _random_state}

func from_dict(data: Dictionary) -> void:
	casts = int(data.get("casts", 0))
	caught = int(data.get("caught", 0))
	best_catch = str(data.get("best_catch", "None"))
	collection = data.get("collection", {})
	_random_state = int(data.get("state", _random_state))
