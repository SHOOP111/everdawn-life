class_name PlayerController
extends RefCounted

const WALK_SPEED := 74.0
const RUN_SPEED := 112.0

var position := Vector2.ZERO
var facing := Vector2.DOWN
var velocity := Vector2.ZERO
var stamina := 100.0
var tools := ["Hoe", "Seeds", "Watering Can", "Hands", "Fishing Rod", "Gather"]
var selected_tool: int = 0
var health: float = 100.0
var warmth: float = 100.0
var distance_walked: float = 0.0
var discovered_regions: Array[String] = ["Everdawn Village"]
var footsteps: float = 0.0

func update(delta: float, world: WorldGenerator, input_enabled: bool = true) -> bool:
	var direction := Vector2.ZERO
	if input_enabled:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	var running := input_enabled and Input.is_action_pressed("sprint") and stamina > 2.0
	var speed := RUN_SPEED if running else WALK_SPEED
	velocity = direction * speed
	if running and direction != Vector2.ZERO:
		stamina = maxf(0.0, stamina - delta * 17.0)
	else:
		stamina = minf(100.0, stamina + delta * 10.0)
	var old_position := position
	var next_x := Vector2(position.x + velocity.x * delta, position.y)
	if not world.is_blocked(next_x):
		position.x = next_x.x
	var next_y := Vector2(position.x, position.y + velocity.y * delta)
	if not world.is_blocked(next_y):
		position.y = next_y.y
	if position != old_position:
		var traveled := old_position.distance_to(position)
		footsteps += traveled
		distance_walked += traveled
	return position != old_position

func target_tile() -> Vector2i:
	return Vector2i((position + facing * 18.0) / WorldGenerator.TILE)

func cycle_tool() -> String:
	selected_tool = (selected_tool + 1) % tools.size()
	return tools[selected_tool]

func current_tool() -> String:
	return tools[selected_tool]

func discover(region_name: String) -> bool:
	if region_name in discovered_regions:
		return false
	discovered_regions.append(region_name)
	return true

func to_dict() -> Dictionary:
	return {"position": [position.x, position.y], "stamina": stamina, "health": health, "warmth": warmth,
		"tool": selected_tool, "facing": [facing.x, facing.y], "distance_walked": distance_walked,
		"discovered_regions": discovered_regions}

func from_dict(data: Dictionary) -> void:
	var pos: Array = data.get("position", [position.x, position.y])
	position = Vector2(float(pos[0]), float(pos[1]))
	stamina = float(data.get("stamina", stamina))
	health = float(data.get("health", health))
	warmth = float(data.get("warmth", warmth))
	distance_walked = float(data.get("distance_walked", distance_walked))
	discovered_regions.clear()
	for region in data.get("discovered_regions", ["Everdawn Village"]):
		discovered_regions.append(str(region))
	selected_tool = int(data.get("tool", selected_tool))
	var face: Array = data.get("facing", [0.0, 1.0])
	facing = Vector2(float(face[0]), float(face[1]))
