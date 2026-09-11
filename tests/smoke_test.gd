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
	check(world.buildings.size() >= 8 and world.landmarks.size() == 5, "settlement and landmark generation")
	check(world.region_name_at(world.town_center) == "Everdawn Village", "world regions")
	var resources := ResourceSystem.new()
	resources.generate(world)
	check(resources.nodes.size() > 100, "resource ecology generation")
	var farm_inventory := FarmSystem.new().inventory
	var available_before := resources.nearby_count(world.town_center, 5000.0)
	var gather_position: Vector2 = resources.nodes[0].position
	var gather_result := resources.gather_near(gather_position, 4.0, farm_inventory, 1)
	check(bool(gather_result.success) and resources.nearby_count(world.town_center, 5000.0) == available_before - 1, "resource gathering")
	var clock := GameClock.new()
	var old_day := clock.day
	clock.advance(90000.0 / clock.time_scale)
	check(clock.day != old_day and clock.minute >= 0.0 and clock.minute < 1440.0, "clock calendar wrap")
	var farm := FarmSystem.new()
	var tile := Vector2i(120, 90)
	check(farm.till(tile, 1.0).begins_with("The earth"), "till plot")
	check(farm.plant(tile).begins_with("Planted"), "plant crop")
	farm.water(tile)
	for day in 10:
		farm.advance_day("Rain")
	check(bool(farm.plots[farm.plot_key(tile)].ready), "crop becomes harvestable")
	check(farm.harvest(tile, 1.5).begins_with("Harvested"), "skill-scaled harvest")
	var citizen := CitizenData.new(3, world.town_center)
	citizen.choose_schedule(10, 2, world.town_center)
	citizen.simulate_needs(60.0, true)
	for conversation in 8:
		citizen.deepen_relationship(conversation)
	check(citizen.hunger > 22.0 and citizen.relationship_stage >= 2, "citizen needs and relationship simulation")
	var skills := SkillSystem.new()
	var level_messages := skills.add_xp("Farming", 1000.0)
	check(skills.level("Farming") > 1 and not level_messages.is_empty(), "skill progression")
	var crafting := CraftingSystem.new()
	var craft_inventory := {"Turnip": 2, "Moonbean": 2}
	check(crafting.craft(craft_inventory, 1).begins_with("Crafted") and int(craft_inventory.get("Field Snack", 0)) == 2, "crafting transaction")
	var economy := EconomySystem.new()
	var sale_inventory := {"Turnip": 2}
	var old_coins := economy.coins
	check(economy.sell_one("Turnip", sale_inventory).begins_with("Sold") and economy.coins > old_coins, "market transaction")
	var festivals := FestivalSystem.new()
	check(festivals.update(7, 12) and festivals.participate(7).begins_with("You joined"), "festival lifecycle")
	var fishing := FishingSystem.new()
	check(fishing.casts == 0 and fishing.collection.is_empty(), "fishing state initialization")
	var quests := QuestSystem.new()
	quests.record("talk", 3)
	quests.record("discover", 3)
	check(bool(quests.quests[1].done) and bool(quests.quests[3].done) and quests.renown == 30, "expanded quest progression")
	var packed := {"clock": clock.to_dict(), "farm": farm.to_dict(), "citizen": citizen.to_dict(),
		"skills": skills.to_dict(), "economy": economy.to_dict(), "crafting": crafting.to_dict(),
		"festival": festivals.to_dict(), "resources": resources.to_dict()}
	var json := JSON.stringify(packed)
	check(JSON.parse_string(json) is Dictionary, "expanded state JSON round-trip")
	if failures.is_empty():
		print("SMOKE PASS: vast world, ecology, clock, crops, citizens, skills, crafting, market, festivals, quests, serialization")
		quit(0)
	else:
		print("SMOKE FAIL: %s" % ", ".join(failures))
		quit(1)
