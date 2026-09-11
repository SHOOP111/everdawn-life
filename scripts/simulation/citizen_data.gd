class_name CitizenData
extends RefCounted

const FIRST_NAMES := ["Mara", "Orin", "Jun", "Lio", "Sable", "Pip", "Iris", "Toma", "Nell", "Rowan", "Aster", "Kite", "Mina", "Bram", "Fenn", "Yara"]
const TRAITS := ["Kind", "Curious", "Bold", "Patient", "Witty", "Dreamy", "Diligent", "Gentle"]
const JOBS := ["Farmer", "Baker", "Carpenter", "Herbalist", "Fisher", "Keeper", "Weaver", "Scholar"]

var id: int
var display_name: String
var age: int
var trait: String
var job: String
var home: Vector2
var workplace: Vector2
var position: Vector2
var destination: Vector2
var energy: float = 82.0
var hunger: float = 22.0
var belonging: float = 68.0
var joy: float = 70.0
var affinity: float = 0.0
var task: String = "Wandering"
var memory: Array[String] = []
var speed: float

func _init(citizen_id: int = 0, spawn: Vector2 = Vector2.ZERO) -> void:
	id = citizen_id
	display_name = FIRST_NAMES[id % FIRST_NAMES.size()]
	age = 18 + ((id * 13 + 7) % 48)
	trait = TRAITS[(id * 5 + 1) % TRAITS.size()]
	job = JOBS[(id * 3 + 2) % JOBS.size()]
	home = spawn
	position = spawn
	destination = spawn
	speed = 15.0 + float(id % 4)

func choose_schedule(hour: int, day: int, town_center: Vector2) -> void:
	var seed := id * 73 + day * 19 + hour * 31
	if energy < 18.0 or hour >= 22 or hour < 6:
		task = "Resting"
		destination = home
	elif hunger > 72.0:
		task = "Getting a meal"
		destination = town_center + Vector2(20, -10)
	elif hour >= 8 and hour < 16 and day % 7 < 5:
		task = "Working as %s" % job
		destination = workplace
	elif belonging < 35.0 or (hour >= 17 and hour < 20):
		task = "Visiting the commons"
		destination = town_center + Vector2(seed % 35 - 17, seed / 7 % 25 - 12)
	else:
		task = "Taking a thoughtful walk"
		destination = home + Vector2(seed % 81 - 40, seed / 11 % 61 - 30)

func simulate_needs(game_minutes: float, is_moving: bool) -> void:
	var hours := game_minutes / 60.0
	hunger = clampf(hunger + hours * (3.2 if is_moving else 2.2), 0.0, 100.0)
	energy = clampf(energy - hours * (2.7 if is_moving else 1.5), 0.0, 100.0)
	belonging = clampf(belonging - hours * 0.8, 0.0, 100.0)
	if task == "Resting":
		energy = clampf(energy + hours * 14.0, 0.0, 100.0)
	if task == "Getting a meal" and position.distance_to(destination) < 8.0:
		hunger = maxf(0.0, hunger - hours * 35.0)
	if task == "Visiting the commons":
		belonging = clampf(belonging + hours * 7.0, 0.0, 100.0)
	joy = clampf((energy + (100.0 - hunger) + belonging) / 3.0 + affinity * 0.08, 0.0, 100.0)

func remember(text: String) -> void:
	memory.push_front(text)
	if memory.size() > 5:
		memory.pop_back()

func greeting() -> String:
	var mood := "bright"
	if energy < 30.0:
		mood = "sleepy"
	elif hunger > 65.0:
		mood = "peckish"
	elif joy < 40.0:
		mood = "quiet"
	var thoughts := [
		"The valley feels %s today." % mood,
		"I'm %s. Every day teaches the hands something new." % task.to_lower(),
		"A %s heart notices details others miss." % trait.to_lower(),
		"They say kindness changes a town one small moment at a time.",
	]
	return thoughts[(id + memory.size()) % thoughts.size()]

func to_dict() -> Dictionary:
	return {"id": id, "name": display_name, "position": [position.x, position.y],
		"energy": energy, "hunger": hunger, "belonging": belonging, "joy": joy,
		"affinity": affinity, "task": task, "memory": memory}

func apply_dict(data: Dictionary) -> void:
	var pos: Array = data.get("position", [position.x, position.y])
	position = Vector2(float(pos[0]), float(pos[1]))
	energy = float(data.get("energy", energy))
	hunger = float(data.get("hunger", hunger))
	belonging = float(data.get("belonging", belonging))
	joy = float(data.get("joy", joy))
	affinity = float(data.get("affinity", affinity))
	task = str(data.get("task", task))
	memory.clear()
	for item in data.get("memory", []):
		memory.append(str(item))
