class_name FestivalSystem
extends RefCounted

const FESTIVALS := {
	7: {"name": "First Bloom Fair", "description": "Flowers, seeds, and new beginnings fill the commons."},
	21: {"name": "Lanternwater Eve", "description": "The town floats lanterns for everything it hopes to remember."},
	35: {"name": "Suncrest Games", "description": "Friendly contests and bright ribbons transform the square."},
	56: {"name": "Midsummer Feast", "description": "Every household brings its finest harvest to one table."},
	70: {"name": "Amberleaf Market", "description": "Rare traders visit beneath falling copper leaves."},
	84: {"name": "Ancestors' Night", "description": "Stories and candlelight hold back the long dark."},
	98: {"name": "Snowbell Jubilee", "description": "Warm drinks, snow sculptures, and gifts for neighbors."},
	112: {"name": "Starwake", "description": "The valley welcomes another year beneath the aurora."},
}

var active_festival: Dictionary = {}
var attended: Dictionary = {}
var festival_points: int = 0

func update(day: int, hour: int) -> bool:
	var previous_name := str(active_festival.get("name", ""))
	active_festival = {}
	if FESTIVALS.has(day) and hour >= 9 and hour < 23:
		active_festival = FESTIVALS[day].duplicate(true)
		active_festival["day"] = day
	return previous_name.is_empty() and not active_festival.is_empty()

func is_active() -> bool:
	return not active_festival.is_empty()

func participate(day: int) -> String:
	if not is_active():
		return "There is no festival in progress."
	var key := str(day)
	if bool(attended.get(key, false)):
		return "You have already joined today's celebration."
	attended[key] = true
	festival_points += 25
	return "You joined %s! The town will remember this." % str(active_festival.name)

func upcoming(day: int) -> String:
	var best_distance := 999
	var best_name := ""
	for festival_day in FESTIVALS:
		var distance := int(festival_day) - day
		if distance < 0:
			distance += 112
		if distance < best_distance:
			best_distance = distance
			best_name = str(FESTIVALS[festival_day].name)
	return "%s in %d day%s" % [best_name, best_distance, "" if best_distance == 1 else "s"]

func to_dict() -> Dictionary:
	return {"attended": attended, "festival_points": festival_points}

func from_dict(data: Dictionary) -> void:
	attended = data.get("attended", {})
	festival_points = int(data.get("festival_points", 0))
