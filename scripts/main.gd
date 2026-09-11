extends Node

var world := WorldGenerator.new()
var clock := GameClock.new()
var farm := FarmSystem.new()
var quests := QuestSystem.new()
var economy := EconomySystem.new()
var skills := SkillSystem.new()
var crafting := CraftingSystem.new()
var fishing := FishingSystem.new()
var festivals := FestivalSystem.new()
var resources := ResourceSystem.new()
var player := PlayerController.new()
var citizens: Array[CitizenData] = []
var world_view: WorldView
var camera: Camera2D
var hud: GameHUD
var schedule_hour: int = -1
var journal_open := false
var autosave_elapsed := 0.0
var current_region := "Everdawn Village"
var last_festival_active := false

func _ready() -> void:
	world.generate()
	resources.generate(world)
	player.position = world.town_center + Vector2(-48, 116)
	_create_citizens()
	world_view = WorldView.new()
	world_view.name = "ProceduralWorld"
	add_child(world_view)
	world_view.configure(world, resources, farm, player, citizens, clock)
	camera = Camera2D.new()
	camera.name = "PixelCamera"
	camera.position = player.position.round()
	camera.zoom = Vector2(2.0, 2.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.world_pixel_size.x)
	camera.limit_bottom = int(world.world_pixel_size.y)
	add_child(camera)
	camera.make_current()
	hud = GameHUD.new()
	hud.name = "HUD"
	add_child(hud)
	clock._roll_weather()
	_schedule_citizens(true)
	hud.toast("Welcome home. A vast living valley awaits.")

func _create_citizens() -> void:
	for i in 16:
		var angle := TAU * float(i) / 16.0
		var spawn := world.town_center + Vector2(cos(angle) * (75 + (i % 4) * 27), sin(angle) * (58 + (i % 3) * 33))
		var citizen := CitizenData.new(i, spawn)
		citizen.home = world.nearest_building_position(i)
		citizen.position = citizen.home + Vector2((i % 3 - 1) * 9, 6)
		citizen.workplace = world.nearest_building_position(i * 3 + 2) + Vector2(0, 8)
		citizens.append(citizen)

func _process(delta: float) -> void:
	var clock_events := clock.advance(delta)
	if bool(clock_events.new_day):
		_advance_day()
	if bool(clock_events.weather_changed):
		hud.toast("The weather turns: %s" % clock.weather)
	if bool(clock_events.season_changed):
		hud.toast("%s has come to the valley." % clock.season_name())
	var festival_started := festivals.update(clock.day, clock.hour())
	if festival_started:
		hud.toast("Festival today: %s!" % str(festivals.active_festival.name))
	var moved := player.update(delta, world, not journal_open)
	_simulate_citizens(delta)
	_update_survival(delta)
	_update_region()
	if clock.hour() != schedule_hour:
		_schedule_citizens(false)
	camera.position = player.position.round()
	var view_size := get_viewport().get_visible_rect().size / camera.zoom
	world_view.tick(delta, camera.position, view_size)
	world_view.selected_citizen = _nearest_citizen(38.0)
	hud.update_hud(clock, player, farm, economy, skills, current_region, crafting, festivals, _context_prompt())
	hud.tick(delta)
	autosave_elapsed += delta
	if autosave_elapsed > 180.0:
		autosave_elapsed = 0.0
		_save(false)
	_handle_input()
	if moved and player.footsteps >= 25.0:
		player.footsteps = 0.0
		_award_xp("Exploration", 0.35)

func _advance_day() -> void:
	farm.advance_day(clock.weather)
	resources.advance_day(clock.day)
	economy.advance_day(clock.day, clock.season_index())
	quests.log_event("Day %d began under %s skies." % [clock.day, clock.weather.to_lower()])
	for citizen in citizens:
		if citizen.birthday_today(clock.day):
			quests.log_event("Today is %s's birthday." % citizen.display_name)

func _update_survival(delta: float) -> void:
	var cold := clock.season_index() == 3 or clock.weather in ["Snow", "Storm"]
	var outdoors := player.position.distance_to(world.town_center) > 380.0
	if cold and outdoors:
		player.warmth = maxf(0.0, player.warmth - delta * 0.55)
	else:
		player.warmth = minf(100.0, player.warmth + delta * 0.8)
	if player.warmth <= 0.0:
		player.health = maxf(1.0, player.health - delta * 1.4)
	else:
		player.health = minf(100.0, player.health + delta * 0.08)

func _update_region() -> void:
	var region := world.region_name_at(player.position)
	if region == current_region:
		return
	current_region = region
	if player.discover(region):
		quests.record("discover", 1, "Discovered %s." % region)
		_award_xp("Exploration", 32.0)
		hud.region_banner(region)

func _handle_input() -> void:
	if Input.is_action_just_pressed("journal"):
		journal_open = hud.toggle_journal(quests, skills, economy, festivals)
	if Input.is_action_just_pressed("crafting"):
		journal_open = hud.toggle_crafting(crafting, skills, farm.inventory)
	if Input.is_action_just_pressed("market"):
		journal_open = hud.toggle_market(economy, farm.inventory)
	if journal_open:
		if Input.is_action_just_pressed("menu_next"):
			if hud.active_panel == "crafting":
				crafting.cycle(1)
				hud.refresh_crafting(crafting, skills, farm.inventory)
			elif hud.active_panel == "market":
				economy.cycle_market(1)
				hud.refresh_market(economy, farm.inventory)
		if Input.is_action_just_pressed("menu_previous"):
			if hud.active_panel == "crafting":
				crafting.cycle(-1)
				hud.refresh_crafting(crafting, skills, farm.inventory)
			elif hud.active_panel == "market":
				economy.cycle_market(-1)
				hud.refresh_market(economy, farm.inventory)
		if Input.is_action_just_pressed("confirm"):
			if hud.active_panel == "crafting":
				_craft()
			elif hud.active_panel == "market":
				_sell_market_item()
		return
	if Input.is_action_just_pressed("cycle_tool"):
		hud.toast("Selected %s" % player.cycle_tool())
	if Input.is_action_just_pressed("cycle_seed"):
		hud.toast(farm.cycle_seed())
	if Input.is_action_just_pressed("use_tool"):
		_use_tool()
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("save_game"):
		_save(true)
	if Input.is_action_just_pressed("load_game"):
		_load()
	if Input.is_action_just_pressed("zoom_in"):
		camera.zoom = (camera.zoom + Vector2.ONE * 0.25).clamp(Vector2.ONE * 1.25, Vector2.ONE * 3.25)
	if Input.is_action_just_pressed("zoom_out"):
		camera.zoom = (camera.zoom - Vector2.ONE * 0.25).clamp(Vector2.ONE * 1.25, Vector2.ONE * 3.25)

func _simulate_citizens(delta: float) -> void:
	var game_minutes := delta * clock.time_scale
	for citizen in citizens:
		var to_target := citizen.destination - citizen.position
		var moving := to_target.length() > 2.0
		if moving:
			var next := citizen.position + to_target.normalized() * citizen.speed * delta
			if not world.is_blocked(next):
				citizen.position = next
			else:
				citizen.destination += Vector2((citizen.id % 3 - 1) * 13, ((citizen.id + 1) % 3 - 1) * 13)
		citizen.simulate_needs(game_minutes, moving)

func _schedule_citizens(initial: bool) -> void:
	schedule_hour = clock.hour()
	for citizen in citizens:
		citizen.choose_schedule(schedule_hour, clock.day, world.town_center)
		if festivals.is_active():
			citizen.task = "Celebrating %s" % str(festivals.active_festival.name)
			citizen.destination = world.town_center + Vector2((citizen.id % 5 - 2) * 18, (citizen.id / 5 - 1) * 16)
		if initial:
			citizen.destination = citizen.position

func _context_prompt() -> String:
	var near := _nearest_citizen(30.0)
	if near >= 0:
		return "[E] %s · %s" % [citizens[near].display_name, citizens[near].relationship_name()]
	var landmark := world.nearest_landmark(player.position, 52.0)
	if landmark >= 0:
		return "[E] Explore %s" % str(world.landmarks[landmark].name)
	if festivals.is_active() and player.position.distance_to(world.town_center) < 130.0:
		return "[E] Join %s" % str(festivals.active_festival.name)
	var tile := player.target_tile()
	var key := farm.plot_key(tile)
	if farm.plots.has(key) and bool(farm.plots[key].ready):
		return "[SPACE] Harvest"
	return "[SPACE] Use %s" % player.current_tool()

func _nearest_citizen(distance: float) -> int:
	var found := -1
	var best := distance
	for citizen in citizens:
		var d := citizen.position.distance_to(player.position)
		if d < best:
			best = d
			found = citizen.id
	return found

func _interact() -> void:
	if festivals.is_active() and player.position.distance_to(world.town_center) < 130.0:
		var result := festivals.participate(clock.day)
		if result.begins_with("You joined"):
			quests.record("festival", 1, result)
			_award_xp("Social", 45.0)
		hud.toast(result)
		return
	var landmark := world.nearest_landmark(player.position, 52.0)
	if landmark >= 0:
		var landmark_name := str(world.landmarks[landmark].name)
		quests.log_event("Studied the mysteries of %s." % landmark_name)
		_award_xp("Exploration", 24.0)
		hud.dialogue(landmark_name, "Old stones hum with a story the valley has not finished telling.")
		return
	var near := _nearest_citizen(34.0)
	if near < 0:
		hud.toast("No one is close enough to speak with.")
		return
	var citizen := citizens[near]
	var milestone := citizen.deepen_relationship(clock.day)
	citizen.remember("You spoke on %s %d." % [clock.season_name(), clock.day_of_season()])
	quests.record("talk", 1, "Shared a moment with %s." % citizen.display_name)
	_award_xp("Social", 8.0)
	if not milestone.is_empty():
		hud.toast(milestone)
	hud.dialogue("%s · %s · %s" % [citizen.display_name, citizen.personality_trait, citizen.relationship_name()], citizen.greeting())

func _use_tool() -> void:
	var tile := player.target_tile()
	var world_pos := Vector2(tile * world.TILE) + Vector2.ONE * 8.0
	var message := ""
	match player.current_tool():
		"Fishing Rod":
			var result := fishing.cast(world, player.position, player.facing, clock.season_index(), clock.weather, skills.level("Fishing"), farm.inventory)
			message = str(result.message)
			if bool(result.success):
				quests.record("fish", 1, message)
				_award_xp("Fishing", 18.0 + float(result.get("rarity", 0)) * 9.0)
		"Gather":
			var result := resources.gather_near(player.position + player.facing * 12.0, 27.0, farm.inventory, skills.level("Foraging"))
			message = str(result.message)
			if bool(result.success):
				_award_xp(str(result.skill), 9.0 * float(result.amount))
		_:
			if world.biome_at(tile.x, tile.y) not in [3, 4]:
				hud.toast("This ground cannot be cultivated.")
				return
			match player.current_tool():
				"Hoe":
					message = farm.till(tile, world.sample_fertility_at(world_pos))
					if message.begins_with("The earth"):
						_award_xp("Farming", 4.0)
				"Seeds":
					message = farm.plant(tile)
					if message.begins_with("Planted"):
						quests.record("plant", 1, message)
						_award_xp("Farming", 7.0)
				"Watering Can":
					message = farm.water(tile)
				"Hands":
					message = farm.harvest(tile, skills.yield_bonus("Farming"))
					if message.begins_with("Harvested"):
						var amount := int(message.split(" ")[1])
						quests.record("harvest", amount, message)
						_award_xp("Farming", 8.0 * amount)
	hud.toast(message)

func _craft() -> void:
	var result := crafting.craft(farm.inventory, skills.level("Crafting"))
	if result.begins_with("Crafted"):
		quests.record("craft", 1, result)
		_award_xp("Crafting", 24.0)
	hud.toast(result)
	hud.refresh_crafting(crafting, skills, farm.inventory)

func _sell_market_item() -> void:
	var before := economy.lifetime_earned
	var result := economy.sell_one(economy.selected_item(), farm.inventory)
	if economy.lifetime_earned > before:
		quests.record("earn", economy.lifetime_earned - before, result)
		_award_xp("Social", 3.0)
	hud.toast(result)
	hud.refresh_market(economy, farm.inventory)

func _award_xp(skill_name: String, amount: float) -> void:
	for message in skills.add_xp(skill_name, amount):
		hud.toast(message)

func _save(show_message: bool) -> void:
	var citizen_data: Array[Dictionary] = []
	for citizen in citizens:
		citizen_data.append(citizen.to_dict())
	var data := {"clock": clock.to_dict(), "player": player.to_dict(), "farm": farm.to_dict(),
		"quests": quests.to_dict(), "economy": economy.to_dict(), "skills": skills.to_dict(),
		"crafting": crafting.to_dict(), "fishing": fishing.to_dict(), "festivals": festivals.to_dict(),
		"resources": resources.to_dict(), "citizens": citizen_data}
	var ok := SaveSystem.save_game(data)
	if show_message:
		hud.toast("Valley saved." if ok else "Could not save the valley.")

func _load() -> void:
	var data := SaveSystem.load_game()
	if data.is_empty():
		hud.toast("No saved valley was found.")
		return
	clock.from_dict(data.get("clock", {}))
	player.from_dict(data.get("player", {}))
	farm.from_dict(data.get("farm", {}))
	quests.from_dict(data.get("quests", {}))
	economy.from_dict(data.get("economy", {}))
	skills.from_dict(data.get("skills", {}))
	crafting.from_dict(data.get("crafting", {}))
	fishing.from_dict(data.get("fishing", {}))
	festivals.from_dict(data.get("festivals", {}))
	resources.from_dict(data.get("resources", {}))
	var saved_citizens: Array = data.get("citizens", [])
	for i in mini(saved_citizens.size(), citizens.size()):
		citizens[i].apply_dict(saved_citizens[i])
	current_region = world.region_name_at(player.position)
	hud.toast("Welcome back to Everdawn.")
