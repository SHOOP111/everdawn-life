extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var world := WorldGenerator.new()
	world.generate()
	check(world.height_map.size() == WorldGenerator.MAP_SIZE.x * WorldGenerator.MAP_SIZE.y, "world map dimensions")
	check(world.buildings.size() >= 8, "settlement generated")
	check(world.sample_fertility_at(world.town_center) >= 0.0, "fertility sample")
	var clock := GameClock.new()
	var old_day := clock.day
	clock.advance(90000.0 / clock.time_scale)
	check(clock.day != old_day, "clock advances day")
	check(clock.minute >= 0.0 and clock.minute < 1440.0, "clock wraps validly")
	var farm := FarmSystem.new()
	var tile := Vector2i(80, 60)
	check(farm.till(tile, 1.0).begins_with("The earth"), "till plot")
	check(farm.plant(tile).begins_with("Planted"), "plant crop")
	farm.water(tile)
	for day in 10:
		farm.advance_day("Rain")
	check(bool(farm.plots[farm.plot_key(tile)].ready), "crop becomes harvestable")
	check(farm.harvest(tile).begins_with("Harvested"), "harvest crop")
	var citizen := CitizenData.new(3, world.town_center)
	citizen.choose_schedule(10, 2, world.town_center)
	citizen.simulate_needs(60.0, true)
	check(citizen.hunger > 22.0, "citizen needs simulation")
	var quests := QuestSystem.new()
	quests.record("talk", 3)
	check(bool(quests.quests[1].done), "quest completion")
	check(quests.renown == 15, "quest reward")
	var packed := {"clock": clock.to_dict(), "farm": farm.to_dict(), "citizen": citizen.to_dict()}
	var json := JSON.stringify(packed)
	check(JSON.parse_string(json) is Dictionary, "state JSON round-trip")
	if failures.is_empty():
		print("SMOKE PASS: world, clock, crops, citizens, quests, serialization")
		quit(0)
	else:
		print("SMOKE FAIL: %s" % ", ".join(failures))
		quit(1)
