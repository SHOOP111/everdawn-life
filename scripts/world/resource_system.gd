class_name ResourceSystem
extends RefCounted

const NODE_TYPES := ["Tree", "Rock", "Herb", "Berry Bush", "Mushroom", "Crystal"]
const RESPAWN_DAYS := {"Tree": 4, "Rock": 6, "Herb": 2, "Berry Bush": 3, "Mushroom": 2, "Crystal": 12}

var nodes: Array[Dictionary] = []
var decorations: Array[Dictionary] = []
var day_marker: int = 1

func generate(world: WorldGenerator) -> void:
	nodes.clear()
	decorations.clear()
	var occupied: Array[Vector2] = []
	for y in range(4, WorldGenerator.MAP_SIZE.y - 4, 3):
		for x in range(4, WorldGenerator.MAP_SIZE.x - 4, 3):
			var biome := world.biome_at(x, y)
			var roll := _hash(x, y, 411)
			var type := ""
			if biome == 5 and roll > 0.34:
				type = "Tree" if roll < 0.84 else ("Mushroom" if roll < 0.96 else "Herb")
			elif biome == 4 and roll > 0.82:
				type = "Herb" if roll < 0.91 else "Berry Bush"
			elif biome == 6 and roll > 0.69:
				type = "Rock" if roll < 0.94 else "Crystal"
			elif biome == 3 and roll > 0.91:
				type = "Rock"
			if not type.is_empty():
				var pos := Vector2(x * WorldGenerator.TILE + 8, y * WorldGenerator.TILE + 9)
				if pos.distance_to(world.town_center) > 330.0:
					nodes.append({"id": nodes.size(), "type": type, "position": pos, "available": true,
						"respawn_day": 0, "quality": 0.75 + _hash(x, y, 812) * 0.75})
					occupied.append(pos)
	for i in 85:
		var angle := float(i) * 2.399963
		var distance := 120.0 + float((i * 47) % 760)
		var pos := world.town_center + Vector2(cos(angle), sin(angle)) * distance
		if not world.is_blocked(pos):
			decorations.append({"position": pos, "kind": i % 4, "variant": _hash(i, i * 7, 98)})

func gather_near(position: Vector2, radius: float, inventory: Dictionary, skill_level: int) -> Dictionary:
	var nearest := -1
	var distance := radius
	for i in nodes.size():
		var node: Dictionary = nodes[i]
		if not bool(node.available):
			continue
		var candidate := position.distance_to(node.position)
		if candidate < distance:
			distance = candidate
			nearest = i
	if nearest < 0:
		return {"success": false, "message": "Nothing gatherable is within reach.", "skill": "Foraging"}
	var node: Dictionary = nodes[nearest]
	var node_type := str(node.type)
	var item_name := ""
	var skill := "Foraging"
	match node_type:
		"Tree":
			item_name = "Wood"
			skill = "Foraging"
		"Rock":
			item_name = "Stone"
			skill = "Exploration"
		"Herb": item_name = "Wild Herb"
		"Berry Bush": item_name = "Berry"
		"Mushroom": item_name = "Mushroom"
		"Crystal":
			item_name = "Crystal"
			skill = "Exploration"
	var amount := 1 + int(float(node.quality) + float(skill_level) * 0.08)
	inventory[item_name] = int(inventory.get(item_name, 0)) + amount
	node.available = false
	node.respawn_day = day_marker + int(RESPAWN_DAYS[node_type])
	nodes[nearest] = node
	return {"success": true, "message": "Gathered %d %s." % [amount, item_name], "skill": skill, "amount": amount}

func advance_day(day: int) -> void:
	day_marker = day
	for i in nodes.size():
		var node: Dictionary = nodes[i]
		if not bool(node.available) and day >= int(node.respawn_day):
			node.available = true
			nodes[i] = node

func nearby_count(position: Vector2, radius: float) -> int:
	var count := 0
	for node in nodes:
		if bool(node.available) and position.distance_to(node.position) < radius:
			count += 1
	return count

func _hash(x: int, y: int, salt: int) -> float:
	var value := x * 374761393 + y * 668265263 + salt * 362437
	value = (value ^ (value >> 13)) * 1274126177
	return float(value & 0xffff) / 65535.0

func to_dict() -> Dictionary:
	var depleted: Array[Dictionary] = []
	for node in nodes:
		if not bool(node.available):
			depleted.append({"id": node.id, "respawn_day": node.respawn_day})
	return {"depleted": depleted, "day_marker": day_marker}

func from_dict(data: Dictionary) -> void:
	day_marker = int(data.get("day_marker", day_marker))
	for entry in data.get("depleted", []):
		var id := int(entry.get("id", -1))
		if id >= 0 and id < nodes.size():
			var node: Dictionary = nodes[id]
			node.available = false
			node.respawn_day = int(entry.get("respawn_day", day_marker + 1))
			nodes[id] = node
