extends Node

var world := WorldGenerator.new()
var clock := GameClock.new()
var farm := FarmSystem.new()
var quests := QuestSystem.new()
var player := PlayerController.new()
var citizens: Array[CitizenData] = []
var world_view: WorldView
var camera: Camera2D
var hud: GameHUD
var schedule_hour: int = -1
var journal_open := false
var autosave_elapsed := 0.0

func _ready() -> void:
	world.generate()
	player.position = world.town_center + Vector2(-48, 116)
	_create_citizens()
	world_view = WorldView.new()
	world_view.name = "ProceduralWorld"
	add_child(world_view)
	world_view.configure(world, farm, player, citizens, clock)
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
	hud.toast("Welcome home. The valley is alive.")

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
		farm.advance_day(clock.weather)
		quests.log_event("Day %d began under %s skies." % [clock.day, clock.weather.to_lower()])
	if bool(clock_events.weather_changed):
		hud.toast("The weather turns: %s" % clock.weather)
	if bool(clock_events.season_changed):
		hud.toast("%s has come to the valley." % clock.season_name())
	var moved := player.update(delta, world, not journal_open)
	_simulate_citizens(delta)
	if clock.hour() != schedule_hour:
		_schedule_citizens(false)
	camera.position = player.position.round()
	var view_size := get_viewport().get_visible_rect().size / camera.zoom
	world_view.tick(delta, camera.position, view_size)
	world_view.selected_citizen = _nearest_citizen(38.0)
	hud.update_hud(clock, player, farm, _context_prompt())
	hud.tick(delta)
	autosave_elapsed += delta
	if autosave_elapsed > 180.0:
		autosave_elapsed = 0.0
		_save(false)
	_handle_input()
	if moved and player.footsteps >= 25.0:
		player.footsteps = 0.0

func _handle_input() -> void:
	if Input.is_action_just_pressed("journal"):
		journal_open = hud.toggle_journal(quests)
	if journal_open:
		return
	if Input.is_action_just_pressed("cycle_tool"):
		hud.toast("Selected %s" % player.cycle_tool())
	if Input.is_action_just_pressed("use_tool"):
		_use_tool()
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("save_game"):
		_save(true)
	if Input.is_action_just_pressed("load_game"):
		_load()
	if Input.is_action_just_pressed("zoom_in"):
		camera.zoom = (camera.zoom + Vector2.ONE * 0.25).clamp(Vector2.ONE * 1.5, Vector2.ONE * 3.0)
	if Input.is_action_just_pressed("zoom_out"):
		camera.zoom = (camera.zoom - Vector2.ONE * 0.25).clamp(Vector2.ONE * 1.5, Vector2.ONE * 3.0)

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
		if initial:
			citizen.destination = citizen.position

func _context_prompt() -> String:
	var near := _nearest_citizen(30.0)
	if near >= 0:
		return "[E] Talk to %s" % citizens[near].display_name
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
	var near := _nearest_citizen(34.0)
	if near < 0:
		hud.toast("No one is close enough to speak with.")
		return
	var citizen := citizens[near]
	citizen.affinity += 3.0
	citizen.belonging = minf(100.0, citizen.belonging + 7.0)
	citizen.remember("You spoke on %s %d." % [clock.season_name(), clock.day_of_season()])
	quests.record("talk", 1, "Shared a moment with %s." % citizen.display_name)
	hud.dialogue("%s · %s %s" % [citizen.display_name, citizen.personality_trait, citizen.job], citizen.greeting())

func _use_tool() -> void:
	var tile := player.target_tile()
	var world_pos := Vector2(tile * world.TILE) + Vector2.ONE * 8.0
	if world.biome_at(tile.x, tile.y) not in [3, 4]:
		hud.toast("This ground cannot be cultivated.")
		return
	var message := ""
	match player.current_tool():
		"Hoe":
			message = farm.till(tile, world.sample_fertility_at(world_pos))
		"Seeds":
			message = farm.plant(tile)
			if message.begins_with("Planted"):
				quests.record("plant", 1, message)
		"Watering Can":
			message = farm.water(tile)
		"Hands":
			message = farm.harvest(tile)
			if message.begins_with("Harvested"):
				var amount := int(message.split(" ")[1])
				quests.record("harvest", amount, message)
	hud.toast(message)

func _save(show_message: bool) -> void:
	var citizen_data: Array[Dictionary] = []
	for citizen in citizens:
		citizen_data.append(citizen.to_dict())
	var data := {"clock": clock.to_dict(), "player": player.to_dict(), "farm": farm.to_dict(),
		"quests": quests.to_dict(), "citizens": citizen_data}
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
	var saved_citizens: Array = data.get("citizens", [])
	for i in mini(saved_citizens.size(), citizens.size()):
		citizens[i].apply_dict(saved_citizens[i])
	hud.toast("Welcome back to Everdawn.")
