extends Node

@export var round_time := 300.0            # 5 minutes
@export var max_health := 100.0
@export var drain_per_broken := 1        # health lost per second, per broken system
@export var fail_penalty := 10.0           # health lost for a wrong answer
@export var first_break_delay := 8.0       # seconds before the first breakdown
@export var break_interval_start := 30.0   # gap between breakdowns at the start
@export var break_interval_end := 10.0     # gap near the end (gets harder)
@export var game_seed := 0                 # 0 = random each round; set a number to replay a round

var modules: Array[PuzzleModule] = []
var rng := RandomNumberGenerator.new()
var time_left := 0.0
var health := 0.0
var running := false
var _next_break := 0.0
var _last_sent_second := -1
var _last_sent_health := -1

func _ready() -> void:
	if not multiplayer.is_server():
		return   # only the ship runs the game
	# Online: wait until ground control has loaded its scene, otherwise it
	# misses the first room/puzzle messages.
	if Network.is_online and not ShipNet.ground_is_ready:
		print("Waiting for Ground Control...")
		await ShipNet.ground_ready
	start_game.call_deferred()   # wait until every puzzle has run _ready()

func start_game() -> void:
	print("GAME STARTED")
	if game_seed == 0:
		game_seed = randi()
	rng.seed = game_seed
	print("Round seed: ", game_seed)
	_create_manual()
	modules.clear()
	for node in get_tree().get_nodes_in_group("puzzle"):
		var m := node as PuzzleModule
		if m == null:
			continue
		modules.append(m)
		m.setup(game_seed + hash(m.room_id), manual.get(m.room_id, []))
		if not m.broken_changed.is_connected(_on_module_broken_changed):
			m.broken_changed.connect(_on_module_broken_changed)
			m.failed.connect(_on_module_failed)
	print("Puzzles found: ", modules.size())
	if modules.is_empty():
		push_error("GameManager found no puzzles - nothing can break!")

	time_left = round_time
	health = max_health
	_next_break = first_break_delay
	running = true
	ShipNet.start_game(game_seed)
	ShipNet.send_manual(manual)
	_sync(true)

func _process(delta: float) -> void:
	if not running:
		return

	time_left -= delta
	health -= _broken_count() * drain_per_broken * delta

	_next_break -= delta
	if _next_break <= 0.0:
		_break_random()
		var progress := 1.0 - time_left / round_time   # 0 at start, 1 at the end
		_next_break = lerpf(break_interval_start, break_interval_end, progress)

	_sync()

	if health <= 0.0:
		_end(false)
	elif time_left <= 0.0:
		_end(true)

func _break_random() -> void:
	var working := modules.filter(func(m): return not m.is_broken)
	if working.is_empty():
		return   # everything is already broken
	var m: PuzzleModule = working[rng.randi_range(0, working.size() - 1)]
	m.break_module()

func _broken_count() -> int:
	return modules.filter(func(m): return m.is_broken).size()

func _on_module_broken_changed(m: PuzzleModule, is_broken: bool) -> void:
	print("%s %s" % [m.puzzle_name, "BROKE" if is_broken else "repaired"])
	if is_broken:
		# Send the fix info first so the map has it when the room starts flashing
		var info := m.answer.duplicate()
		info.erase("solution")
		info["puzzle"] = m.puzzle_name
		ShipNet.send_puzzle_info(m.room_id, info)
	ShipNet.set_room_broken(m.room_id, is_broken)

func _on_module_failed(_m: PuzzleModule) -> void:
	if running:
		health -= fail_penalty

# Only send to the network when the number on screen actually changes
func _sync(force := false) -> void:
	var sec := ceili(maxf(time_left, 0.0))
	var hp := ceili(maxf(health, 0.0))
	if force or sec != _last_sent_second:
		_last_sent_second = sec
		ShipNet.set_time_left(sec)
	if force or hp != _last_sent_health:
		_last_sent_health = hp
		ShipNet.set_ship_health(hp)

func _end(won: bool) -> void:
	running = false
	_sync(true)
	ShipNet.end_game(won)
	print("YOU SURVIVED!" if won else "SHIP DESTROYED")
	


# room_id -> [how many values, min, max, number of levels]
const MANUAL_SPEC := {
	"cockpit":      [2, 100, 275, 1],   # Landing: X, Y
	"right_wing":   [4, 0, 3, 3],       # Radiation
	"left_wing":    [3, 0, 3, 3],       # Vents
	"lower_engine": [5, 0, 1, 4],       # Temperature
}

var manual := {} 

func _create_manual() -> void:
	manual.clear()
	for room_id in MANUAL_SPEC:
		var spec: Array = MANUAL_SPEC[room_id]
		var rules: Array = []
		while rules.size() < spec[3]:
			var rule: Array = []
			for i in spec[0]:
				rule.append(rng.randi_range(spec[1], spec[2]))
			if not rule in rules:  
				rules.append(rule)
		manual[room_id] = rules
