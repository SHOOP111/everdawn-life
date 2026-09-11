class_name WorldView
extends Node2D

var world: WorldGenerator
var farm: FarmSystem
var player: PlayerController
var citizens: Array[CitizenData] = []
var clock: GameClock
var camera_position := Vector2.ZERO
var viewport_world_size := Vector2(640, 360)
var animation_time := 0.0
var selected_citizen: int = -1

func configure(p_world: WorldGenerator, p_farm: FarmSystem, p_player: PlayerController,
		p_citizens: Array[CitizenData], p_clock: GameClock) -> void:
	world = p_world
	farm = p_farm
	player = p_player
	citizens = p_citizens
	clock = p_clock
	queue_redraw()

func tick(delta: float, center: Vector2, view_size: Vector2) -> void:
	animation_time += delta
	camera_position = center
	viewport_world_size = view_size
	queue_redraw()

func _draw() -> void:
	if world == null:
		return
	var margin := 32.0
	var bounds := Rect2(camera_position - viewport_world_size * 0.5 - Vector2.ONE * margin,
		viewport_world_size + Vector2.ONE * margin * 2.0)
	var min_tile := Vector2i(maxi(0, floori(bounds.position.x / world.TILE)), maxi(0, floori(bounds.position.y / world.TILE)))
	var max_tile := Vector2i(mini(world.MAP_SIZE.x - 1, ceili(bounds.end.x / world.TILE)), mini(world.MAP_SIZE.y - 1, ceili(bounds.end.y / world.TILE)))
	_draw_terrain(min_tile, max_tile)
	_draw_roads(bounds)
	_draw_farm(bounds)
	_draw_decor(min_tile, max_tile)
	_draw_buildings(bounds)
	_draw_citizens(bounds)
	_draw_player()
	_draw_target()
	_draw_weather(bounds)
	_draw_daylight(bounds)

func _terrain_color(biome: int) -> Color:
	match biome:
		0: return Palette.DEEP_WATER
		1: return Palette.WATER
		2: return Palette.SAND
		3: return Palette.DRY_GRASS
		4: return Palette.season_grass(clock.season_index())
		5: return Palette.FOREST
		_: return Palette.HIGHLAND

func _draw_terrain(min_tile: Vector2i, max_tile: Vector2i) -> void:
	for y in range(min_tile.y, max_tile.y + 1):
		for x in range(min_tile.x, max_tile.x + 1):
			var biome := world.biome_at(x, y)
			var pos := Vector2(x * world.TILE, y * world.TILE)
			draw_rect(Rect2(pos, Vector2.ONE * world.TILE), _terrain_color(biome))
			var hash := _hash(x, y)
			if biome <= 1:
				var wave_x := fmod(animation_time * 8.0 + hash * 13.0, 14.0)
				draw_line(pos + Vector2(wave_x, 5 + int(hash * 7.0)), pos + Vector2(minf(15.0, wave_x + 4.0), 5 + int(hash * 7.0)), Palette.FOAM.darkened(0.18), 1.0)
			elif biome in [3, 4] and hash > 0.78:
				var fleck := Palette.LIGHT_GRASS if biome == 4 else Palette.SAND.darkened(0.12)
				draw_rect(Rect2(pos + Vector2(3 + int(hash * 7.0), 8), Vector2(1, 3)), fleck)

func _draw_roads(bounds: Rect2) -> void:
	for road in world.roads:
		var rect := Rect2(road)
		if not rect.intersects(bounds):
			continue
		draw_rect(rect, Palette.DARK_DIRT)
		draw_rect(rect.grow(-2), Palette.DIRT)
		if rect.size.x > rect.size.y:
			for x in range(int(rect.position.x) + 4, int(rect.end.x), 13):
				draw_rect(Rect2(x, rect.position.y + rect.size.y * 0.5, 4, 1), Palette.SAND.darkened(0.18))
		else:
			for y in range(int(rect.position.y) + 4, int(rect.end.y), 13):
				draw_rect(Rect2(rect.position.x + rect.size.x * 0.5, y, 1, 4), Palette.SAND.darkened(0.18))

func _draw_decor(min_tile: Vector2i, max_tile: Vector2i) -> void:
	for y in range(min_tile.y, max_tile.y + 1):
		for x in range(min_tile.x, max_tile.x + 1):
			var biome := world.biome_at(x, y)
			var h := _hash(x + 991, y - 337)
			var pos := Vector2(x * world.TILE + 8, y * world.TILE + 9)
			if biome == 5 and h > 0.49:
				_draw_tree(pos, h)
			elif biome == 4 and h > 0.91:
				_draw_flower(pos, h)
			elif biome == 6 and h > 0.84:
				draw_rect(Rect2(pos - Vector2(3, 2), Vector2(7, 4)), Palette.INK.lightened(0.25))
				draw_rect(Rect2(pos - Vector2(2, 3), Vector2(4, 2)), Palette.HIGHLAND.lightened(0.25))

func _draw_tree(pos: Vector2, variant: float) -> void:
	draw_ellipse_shadow(pos + Vector2(0, 5), Vector2(8, 4))
	draw_rect(Rect2(pos.x - 2, pos.y - 5, 4, 11), Palette.DARK_WOOD)
	var leaf := Palette.FOREST.darkened(0.08) if clock.season_index() != 2 else Color("8b6d3e")
	if clock.season_index() == 3:
		leaf = Color("48615b")
	draw_rect(Rect2(pos.x - 7, pos.y - 12, 14, 10), leaf.darkened(0.18))
	draw_rect(Rect2(pos.x - 5, pos.y - 15, 11, 12), leaf)
	draw_rect(Rect2(pos.x - 3, pos.y - 14, 5, 3), leaf.lightened(0.18))
	if variant > 0.8 and clock.season_index() == 0:
		draw_rect(Rect2(pos.x + 3, pos.y - 10, 2, 2), Color("e88b9d"))

func _draw_flower(pos: Vector2, variant: float) -> void:
	var flower := Color("f0a5be") if variant > 0.96 else Color("f4df88")
	draw_rect(Rect2(pos.x, pos.y - 3, 1, 4), Palette.FOREST)
	draw_rect(Rect2(pos.x - 1, pos.y - 4, 3, 2), flower)

func _draw_buildings(bounds: Rect2) -> void:
	for building in world.buildings:
		var rect: Rect2 = building.rect
		if not rect.grow(18).intersects(bounds):
			continue
		var style := int(building.style)
		var roof := Palette.ROOF_RED if style % 2 == 0 else Palette.ROOF_BLUE
		draw_ellipse_shadow(rect.position + Vector2(rect.size.x * 0.5, rect.size.y + 5), Vector2(rect.size.x * 0.53, 8))
		draw_rect(rect, Palette.CREAM.darkened(0.12))
		for x in range(int(rect.position.x) + 4, int(rect.end.x) - 3, 8):
			draw_rect(Rect2(x, rect.position.y + 20, 5, 1), Palette.CREAM.darkened(0.2))
		draw_rect(Rect2(rect.position.x - 5, rect.position.y - 7, rect.size.x + 10, 24), roof.darkened(0.25))
		draw_colored_polygon(PackedVector2Array([rect.position + Vector2(-8, 2), rect.position + Vector2(rect.size.x * 0.5, -18), rect.position + Vector2(rect.size.x + 8, 2)]), roof)
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.5 - 7, rect.end.y - 22, 14, 22), Palette.DARK_WOOD)
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.5 + 3, rect.end.y - 12, 2, 2), Palette.GOLD)
		for side: float in [0.22, 0.76]:
			var wx: float = rect.position.x + rect.size.x * side - 5
			draw_rect(Rect2(wx, rect.position.y + 24, 10, 10), Palette.DARK_WOOD)
			draw_rect(Rect2(wx + 2, rect.position.y + 26, 6, 6), Color("8dc6c4"))
			draw_line(Vector2(wx + 5, rect.position.y + 26), Vector2(wx + 5, rect.position.y + 32), Palette.CREAM.darkened(0.2))

func _draw_farm(bounds: Rect2) -> void:
	for key in farm.plots:
		var plot: Dictionary = farm.plots[key]
		var tile_data: Array = plot.tile
		var pos := Vector2(float(tile_data[0]) * world.TILE, float(tile_data[1]) * world.TILE)
		if not bounds.has_point(pos):
			continue
		draw_rect(Rect2(pos, Vector2.ONE * 16), Palette.DARK_DIRT)
		for row in 3:
			draw_line(pos + Vector2(2, 4 + row * 5), pos + Vector2(14, 4 + row * 5), Palette.DIRT, 1.0)
		if float(plot.water) > 0.2:
			draw_rect(Rect2(pos + Vector2(2, 2), Vector2(12, 1)), Palette.WATER.lightened(0.12))
		var crop := int(plot.crop)
		if crop >= 0:
			var growth := clampf(float(plot.growth), 0.08, 1.0)
			var plant_color: Color = [Color("89bd58"), Color("6faa58"), Color("d6a84b"), Color("6f9bc6")][crop]
			for px in [4, 9, 13]:
				var ph := 2.0 + growth * 8.0
				draw_rect(Rect2(pos.x + px, pos.y + 13 - ph, 2, ph), Palette.FOREST)
				if growth > 0.45:
					draw_rect(Rect2(pos.x + px - 1, pos.y + 12 - ph, 4, 3), plant_color)
			if bool(plot.ready):
				draw_circle(pos + Vector2(13, 3), 2.0 + sin(animation_time * 3.0), Palette.GOLD)

func _draw_citizens(bounds: Rect2) -> void:
	var sorted := citizens.duplicate()
	sorted.sort_custom(func(a: CitizenData, b: CitizenData) -> bool: return a.position.y < b.position.y)
	for citizen in sorted:
		if bounds.has_point(citizen.position):
			_draw_person(citizen.position, citizen.id + 1, citizen.position.distance_to(player.position) < 30.0, citizen.id == selected_citizen)

func _draw_player() -> void:
	_draw_person(player.position, 0, true, false)
	var bob := 1.0 if player.velocity.length() > 1.0 and fmod(animation_time * 8.0, 2.0) > 1.0 else 0.0
	draw_rect(Rect2(player.position.x + player.facing.x * 7 - 1, player.position.y - 5 + player.facing.y * 5 + bob, 3, 9), Palette.WOOD)

func _draw_person(pos: Vector2, variant: int, close: bool, selected: bool) -> void:
	var bob := sin(animation_time * 6.0 + variant) * 0.6
	draw_ellipse_shadow(pos + Vector2(0, 5), Vector2(6, 3))
	var shirt_colors := [Color("457e8c"), Color("b45a55"), Color("7468a6"), Color("5b8f55"), Color("c18a4d"), Color("8b5d78")]
	var shirt: Color = shirt_colors[variant % shirt_colors.size()]
	draw_rect(Rect2(pos.x - 4, pos.y - 5 + bob, 8, 10), shirt.darkened(0.18))
	draw_rect(Rect2(pos.x - 3, pos.y - 6 + bob, 6, 8), shirt)
	draw_rect(Rect2(pos.x - 3, pos.y - 12 + bob, 6, 6), Palette.SKIN)
	draw_rect(Rect2(pos.x - 4, pos.y - 13 + bob, 8, 3), Palette.DARK_WOOD.darkened(float(variant % 3) * 0.08))
	draw_rect(Rect2(pos.x - 2, pos.y - 9 + bob, 1, 1), Palette.INK)
	draw_rect(Rect2(pos.x + 1, pos.y - 9 + bob, 1, 1), Palette.INK)
	if close:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-4, -17), "!", HORIZONTAL_ALIGNMENT_CENTER, 8, 10, Palette.GOLD)
	if selected:
		draw_arc(pos + Vector2(0, 1), 10, 0, TAU, 16, Palette.GOLD, 1.0)

func _draw_target() -> void:
	var tile := player.target_tile()
	var rect := Rect2(Vector2(tile * world.TILE), Vector2.ONE * world.TILE)
	draw_rect(rect, Color(1.0, 0.88, 0.45, 0.18), true)
	draw_rect(rect, Color(1.0, 0.88, 0.45, 0.7), false, 1.0)

func _draw_weather(bounds: Rect2) -> void:
	if clock.weather in ["Rain", "Drizzle", "Storm", "Sunshower"]:
		var count := 95 if clock.weather == "Storm" else 48
		for i in count:
			var x := bounds.position.x + fmod(float(i * 83) + animation_time * 94.0, bounds.size.x)
			var y := bounds.position.y + fmod(float(i * 47) + animation_time * 176.0, bounds.size.y)
			draw_line(Vector2(x, y), Vector2(x - 3, y + 8), Color(0.65, 0.82, 0.95, 0.45), 1.0)
	elif clock.weather == "Snow":
		for i in 55:
			var x := bounds.position.x + fmod(float(i * 97) + sin(animation_time + i) * 12.0, bounds.size.x)
			var y := bounds.position.y + fmod(float(i * 53) + animation_time * 22.0, bounds.size.y)
			draw_circle(Vector2(x, y), 1.2, Color(0.92, 0.96, 1.0, 0.75))

func _draw_daylight(bounds: Rect2) -> void:
	var strength := clock.sun_strength()
	var night_alpha := (1.0 - strength) * 0.68
	if night_alpha > 0.02:
		var night_tint := Palette.NIGHT
		night_tint.a = night_alpha
		draw_rect(bounds, night_tint)
	if clock.weather in ["Rain", "Storm", "Mist"]:
		draw_rect(bounds, Color(0.25, 0.35, 0.42, 0.12 if clock.weather != "Storm" else 0.25))

func draw_ellipse_shadow(center: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, Palette.SHADOW)

func _hash(x: int, y: int) -> float:
	var n := x * 92837111 + y * 689287499 + 283923481
	n = (n ^ (n >> 13)) * 1274126177
	return float(n & 0xffff) / 65535.0
