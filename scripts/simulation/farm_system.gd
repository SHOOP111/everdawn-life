class_name FarmSystem
extends RefCounted

const CROP_NAMES := ["Turnip", "Moonbean", "Sunroot", "Bluebell"]
const GROWTH_DAYS := [3.0, 5.0, 7.0, 4.0]

var plots: Dictionary = {}
var inventory := {"Turnip Seeds": 12, "Moonbean Seeds": 8, "Sunroot Seeds": 6, "Bluebell Seeds": 8,
	"Turnip": 0, "Moonbean": 0, "Sunroot": 0, "Bluebell": 0, "Wild Herb": 0, "Berry": 0,
	"Mushroom": 0, "Fish": 0, "Crystal": 0, "Wood": 8, "Stone": 4, "Field Snack": 0,
	"Herbal Tonic": 0, "Wooden Fence": 0, "Stone Path": 0, "Bee House": 0, "Preserves Jar": 0,
	"Moon Lantern": 0, "Ancient Compass": 0}
var selected_seed: int = 0

func plot_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

func till(tile: Vector2i, fertility: float) -> String:
	var key := plot_key(tile)
	if plots.has(key):
		return "That soil is already tended."
	plots[key] = {"tile": [tile.x, tile.y], "crop": -1, "growth": 0.0, "water": 0.0,
		"fertility": fertility, "ready": false}
	return "The earth is ready for seed."

func plant(tile: Vector2i) -> String:
	var key := plot_key(tile)
	if not plots.has(key):
		return "Till the earth first."
	var plot: Dictionary = plots[key]
	if int(plot.crop) >= 0:
		return "Something is already growing here."
	var seed_name := "%s Seeds" % CROP_NAMES[selected_seed]
	if int(inventory.get(seed_name, 0)) <= 0:
		return "No %s left." % seed_name
	inventory[seed_name] -= 1
	plot.crop = selected_seed
	plot.growth = 0.0
	plot.ready = false
	plots[key] = plot
	return "Planted %s." % CROP_NAMES[selected_seed]

func water(tile: Vector2i) -> String:
	var key := plot_key(tile)
	if not plots.has(key):
		return "There is nothing to water."
	var plot: Dictionary = plots[key]
	plot.water = 1.0
	plots[key] = plot
	return "The soil drinks deeply."

func harvest(tile: Vector2i, skill_multiplier: float = 1.0) -> String:
	var key := plot_key(tile)
	if not plots.has(key):
		return "Nothing to harvest."
	var plot: Dictionary = plots[key]
	if not bool(plot.ready):
		return "It needs more time."
	var crop_id := int(plot.crop)
	var crop_name: String = CROP_NAMES[crop_id]
	var yield_count := maxi(1, roundi((2.0 + float(plot.fertility) * 3.0) * skill_multiplier))
	inventory[crop_name] = int(inventory.get(crop_name, 0)) + yield_count
	plots.erase(key)
	return "Harvested %d %s." % [yield_count, crop_name]

func advance_day(weather: String) -> void:
	for key in plots.keys():
		var plot: Dictionary = plots[key]
		if weather in ["Rain", "Drizzle", "Storm", "Sunshower"]:
			plot.water = 1.0
		if int(plot.crop) >= 0:
			var growth_rate := (0.45 + float(plot.fertility) * 0.7) * (0.35 + float(plot.water) * 0.65)
			plot.growth += growth_rate / GROWTH_DAYS[int(plot.crop)]
			plot.ready = float(plot.growth) >= 1.0
		plot.water = maxf(0.0, float(plot.water) - 0.55)
		plots[key] = plot

func cycle_seed() -> String:
	selected_seed = (selected_seed + 1) % CROP_NAMES.size()
	return "Selected %s Seeds" % CROP_NAMES[selected_seed]

func to_dict() -> Dictionary:
	return {"plots": plots, "inventory": inventory, "selected_seed": selected_seed}

func from_dict(data: Dictionary) -> void:
	plots = data.get("plots", {})
	inventory = data.get("inventory", inventory)
	selected_seed = int(data.get("selected_seed", 0))
