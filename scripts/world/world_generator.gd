class_name WorldGenerator
extends RefCounted

const TILE := 16
const MAP_SIZE := Vector2i(160, 120)
const WORLD_SEED := 0xE7E2

var height_map := PackedFloat32Array()
var moisture_map := PackedFloat32Array()
var fertility_map := PackedFloat32Array()
var roads: Array[Rect2i] = []
var buildings: Array[Dictionary] = []
var ponds: Array[Vector2] = []
var town_center := Vector2(MAP_SIZE.x * TILE * 0.5, MAP_SIZE.y * TILE * 0.5)
var world_pixel_size := Vector2(MAP_SIZE.x * TILE, MAP_SIZE.y * TILE)

func generate() -> void:
	height_map.resize(MAP_SIZE.x * MAP_SIZE.y)
	moisture_map.resize(MAP_SIZE.x * MAP_SIZE.y)
	fertility_map.resize(MAP_SIZE.x * MAP_SIZE.y)
	for y in MAP_SIZE.y:
		for x in MAP_SIZE.x:
			var index := y * MAP_SIZE.x + x
			var nx := float(x) / MAP_SIZE.x
			var ny := float(y) / MAP_SIZE.y
			var island := 1.0 - pow(Vector2(nx - 0.5, ny - 0.5).length() * 1.25, 3.0)
			var broad := _fbm(x * 0.045, y * 0.045, WORLD_SEED, 4)
			var detail := _fbm(x * 0.13, y * 0.13, WORLD_SEED + 99, 3)
			height_map[index] = island * 0.7 + broad * 0.23 + detail * 0.07
			moisture_map[index] = _fbm(x * 0.07, y * 0.07, WORLD_SEED + 307, 4)
			fertility_map[index] = clampf(moisture_map[index] * 0.55 + (1.0 - absf(height_map[index] - 0.58)) * 0.45, 0.0, 1.0)
	_create_settlement()

func _hash(x: int, y: int, seed: int) -> float:
	var n := x * 374761393 + y * 668265263 + seed * 144269
	n = (n ^ (n >> 13)) * 1274126177
	return float(n & 0x7fffffff) / 2147483647.0

func _smooth_noise(x: float, y: float, seed: int) -> float:
	var ix := floori(x)
	var iy := floori(y)
	var fx := smoothstep(0.0, 1.0, x - ix)
	var fy := smoothstep(0.0, 1.0, y - iy)
	var a := _hash(ix, iy, seed)
	var b := _hash(ix + 1, iy, seed)
	var c := _hash(ix, iy + 1, seed)
	var d := _hash(ix + 1, iy + 1, seed)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)

func _fbm(x: float, y: float, seed: int, octaves: int) -> float:
	var value := 0.0
	var amplitude := 0.55
	var total := 0.0
	for octave in octaves:
		value += _smooth_noise(x, y, seed + octave * 101) * amplitude
		total += amplitude
		x *= 2.03
		y *= 2.03
		amplitude *= 0.5
	return value / total

func _create_settlement() -> void:
	roads = [
		Rect2i(int(town_center.x) - 360, int(town_center.y) - 9, 720, 18),
		Rect2i(int(town_center.x) - 9, int(town_center.y) - 260, 18, 520),
		Rect2i(int(town_center.x) - 240, int(town_center.y) + 146, 480, 14),
	]
	buildings.clear()
	var specs := [
		[-178, -100, 76, 55, "Bakery"], [82, -108, 86, 62, "Workshop"],
		[-182, 54, 68, 50, "Cottage"], [100, 62, 72, 54, "Herbalist"],
		[-52, -180, 104, 68, "Town Hall"], [-286, 40, 82, 58, "Farmhouse"],
		[210, -22, 76, 55, "Weavery"], [-65, 192, 65, 48, "Cottage"],
	]
	for i in specs.size():
		var s: Array = specs[i]
		var pos := town_center + Vector2(float(s[0]), float(s[1]))
		buildings.append({"rect": Rect2(pos, Vector2(float(s[2]), float(s[3]))), "name": s[4], "style": i})
	ponds = [town_center + Vector2(-440, -210), town_center + Vector2(405, 275)]

func sample_height(tile_x: int, tile_y: int) -> float:
	if tile_x < 0 or tile_y < 0 or tile_x >= MAP_SIZE.x or tile_y >= MAP_SIZE.y:
		return 0.0
	return height_map[tile_y * MAP_SIZE.x + tile_x]

func sample_moisture(tile_x: int, tile_y: int) -> float:
	if tile_x < 0 or tile_y < 0 or tile_x >= MAP_SIZE.x or tile_y >= MAP_SIZE.y:
		return 0.0
	return moisture_map[tile_y * MAP_SIZE.x + tile_x]

func sample_fertility_at(world_pos: Vector2) -> float:
	var tx := clampi(int(world_pos.x / TILE), 0, MAP_SIZE.x - 1)
	var ty := clampi(int(world_pos.y / TILE), 0, MAP_SIZE.y - 1)
	return fertility_map[ty * MAP_SIZE.x + tx]

func biome_at(tile_x: int, tile_y: int) -> int:
	var h := sample_height(tile_x, tile_y)
	var m := sample_moisture(tile_x, tile_y)
	if h < 0.28: return 0 # deep water
	if h < 0.34: return 1 # shallows
	if h < 0.39: return 2 # sand
	if h > 0.78: return 6 # highland
	if m > 0.69: return 5 # forest
	if m < 0.30: return 3 # dry grass
	return 4 # meadow

func is_blocked(pos: Vector2) -> bool:
	if pos.x < 12.0 or pos.y < 12.0 or pos.x > world_pixel_size.x - 12.0 or pos.y > world_pixel_size.y - 12.0:
		return true
	var tile := Vector2i(pos / TILE)
	if biome_at(tile.x, tile.y) <= 1:
		return true
	for building in buildings:
		var rect: Rect2 = building.rect
		if rect.grow(4.0).has_point(pos):
			return true
	return false

func nearest_building_position(index: int) -> Vector2:
	var building: Dictionary = buildings[index % buildings.size()]
	var rect: Rect2 = building.rect
	return rect.position + Vector2(rect.size.x * 0.5, rect.size.y + 12.0)
