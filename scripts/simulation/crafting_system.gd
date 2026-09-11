class_name CraftingSystem
extends RefCounted

const RECIPES: Array[Dictionary] = [
	{"name": "Field Snack", "ingredients": {"Turnip": 1, "Moonbean": 1}, "result": {"Field Snack": 2}, "skill": 1},
	{"name": "Wooden Fence", "ingredients": {"Wood": 3}, "result": {"Wooden Fence": 2}, "skill": 1},
	{"name": "Stone Path", "ingredients": {"Stone": 3}, "result": {"Stone Path": 2}, "skill": 1},
	{"name": "Herbal Tonic", "ingredients": {"Wild Herb": 3, "Bluebell": 1}, "result": {"Herbal Tonic": 1}, "skill": 2},
	{"name": "Bee House", "ingredients": {"Wood": 8, "Stone": 3, "Wild Herb": 2}, "result": {"Bee House": 1}, "skill": 3},
	{"name": "Preserves Jar", "ingredients": {"Wood": 5, "Stone": 6, "Sunroot": 2}, "result": {"Preserves Jar": 1}, "skill": 4},
	{"name": "Moon Lantern", "ingredients": {"Stone": 4, "Bluebell": 3, "Crystal": 1}, "result": {"Moon Lantern": 1}, "skill": 5},
	{"name": "Ancient Compass", "ingredients": {"Wood": 4, "Stone": 4, "Crystal": 3}, "result": {"Ancient Compass": 1}, "skill": 7},
]

var selected_recipe: int = 0
var crafted_total: int = 0

func current_recipe() -> Dictionary:
	return RECIPES[selected_recipe]

func cycle(direction: int = 1) -> String:
	selected_recipe = posmod(selected_recipe + direction, RECIPES.size())
	return str(current_recipe().name)

func can_craft(inventory: Dictionary, crafting_level: int) -> bool:
	var recipe := current_recipe()
	if crafting_level < int(recipe.skill):
		return false
	var ingredients: Dictionary = recipe.ingredients
	for item_name in ingredients:
		if int(inventory.get(item_name, 0)) < int(ingredients[item_name]):
			return false
	return true

func craft(inventory: Dictionary, crafting_level: int) -> String:
	var recipe := current_recipe()
	if crafting_level < int(recipe.skill):
		return "Requires Crafting level %d." % int(recipe.skill)
	var ingredients: Dictionary = recipe.ingredients
	for item_name in ingredients:
		if int(inventory.get(item_name, 0)) < int(ingredients[item_name]):
			return "Missing %s." % str(item_name)
	for item_name in ingredients:
		inventory[item_name] = int(inventory.get(item_name, 0)) - int(ingredients[item_name])
	var results: Dictionary = recipe.result
	for item_name in results:
		inventory[item_name] = int(inventory.get(item_name, 0)) + int(results[item_name])
	crafted_total += 1
	return "Crafted %s." % str(recipe.name)

func recipe_text(crafting_level: int, inventory: Dictionary) -> String:
	var recipe := current_recipe()
	var parts: Array[String] = []
	var ingredients: Dictionary = recipe.ingredients
	for item_name in ingredients:
		parts.append("%s %d/%d" % [item_name, int(inventory.get(item_name, 0)), int(ingredients[item_name])])
	var lock_text := "" if crafting_level >= int(recipe.skill) else "  [LOCKED: level %d]" % int(recipe.skill)
	return "%s%s\n%s" % [recipe.name, lock_text, " · ".join(parts)]

func to_dict() -> Dictionary:
	return {"selected_recipe": selected_recipe, "crafted_total": crafted_total}

func from_dict(data: Dictionary) -> void:
	selected_recipe = clampi(int(data.get("selected_recipe", 0)), 0, RECIPES.size() - 1)
	crafted_total = int(data.get("crafted_total", 0))
