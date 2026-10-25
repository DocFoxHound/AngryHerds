extends SceneTree
## Plays levels like a fairly accurate kid would, to measure difficulty: aims straight at the
## nearest wolf (with a little wobble), uses each ability when close, and reports whether the
## level was won, with how many animals to spare, and the stars earned.
##   godot --headless --fixed-fps 60 --path . --script res://tools/autoplay.gd -- [first] [last] [tries]
const Levels := preload("res://scripts/levels.gd")
const Catalog := preload("res://scripts/catalog.gd")

var target := Vector2.ZERO


func _initialize() -> void:
	run.call_deferred()


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 1
	var last := int(args[1]) if args.size() > 1 else Levels.COUNT
	var tries := int(args[2]) if args.size() > 2 else 1
	var game = root.get_node("Game")
	game.saving = false
	game.unlock_all = true
	var lost := []
	for n in range(first, last + 1):
		_pick_lineup(game, n)
		var wins := 0
		var stars_total := 0
		var spare_total := 0
		for attempt in tries:
			var result: Array = await _play(game, n)
			if result[0]:
				wins += 1
				stars_total += result[1]
				spare_total += result[2]
		var main = current_scene
		print("%s wolves %d slots %d herd %s: won %d/%d, avg stars %.1f, spare %.1f" % [Levels.label(n),
			main.level.wolves.size(), main.level.slots, ",".join(game.lineup_for(main.level.slots)), wins, tries,
			stars_total / maxf(wins, 1.0), spare_total / maxf(wins, 1.0)])
		if wins < tries:
			lost.append(n)
	print("NOT ALWAYS WON: ", lost)
	quit()


## A kid's lineup: the newest animals they have, mixed with the old favourites.
func _pick_lineup(game, n: int) -> void:
	var owned := []
	for kind in Catalog.LINEUP_ORDER:
		if Catalog.ANIMALS[kind].unlock <= n:
			owned.append(kind)
	owned.reverse()
	for i in Catalog.LINEUP_SIZE:
		game.lineup[i] = owned[i % owned.size()]


func _play(game, n: int) -> Array:
	game.current_level = n
	change_scene_to_file("res://scenes/main.tscn")
	await wait_seconds(1.8)
	var main = current_scene
	var elapsed := 0.0
	while main.state == main.State.PLAYING and elapsed < 120.0:
		var sling = main.slingshot
		if sling.animal == null or main.loading or not main.in_flight.is_empty():
			await wait_seconds(0.25)
			elapsed += 0.25
			continue
		var wolves := main.get_tree().get_nodes_in_group("wolves")
		if wolves.is_empty():
			await wait_seconds(0.25)
			continue
		wolves.sort_custom(func(a, b) -> bool: return a.global_position.x < b.global_position.x)
		target = wolves[0].global_position
		var pull: Vector2 = aim(sling.global_position, target, sling.POWER)
		pull = pull.rotated(randf_range(-0.025, 0.025)) * randf_range(0.97, 1.03)
		sling.pull = pull.limit_length(sling.MAX_PULL)
		sling.animal.global_position = sling.global_position + sling.pull
		sling._release()
		var flier = main.flier
		if OS.get_environment("BOT_DEBUG") != "":
			print("  shot %s at %s pull %s" % [flier.kind, target.round(), pull.round()])
			flier.body_entered.connect(func(b: Node) -> void: print("    hit %s %s at %s" % [b.get_class(), b.get("kind") if b.get("kind") else b.get("variant"), flier.global_position.round()]), CONNECT_ONE_SHOT)
		while is_instance_valid(flier) and not flier.done and main.state == main.State.PLAYING:
			if flier.can_use_ability() and ability_now(flier, target):
				main._try_ability()
			await physics_frame
			elapsed += 1.0 / 120.0
		await wait_seconds(0.5)
		elapsed += 0.5
	while main.state == main.State.WON and not main.results_shown:
		await wait_seconds(0.25)
	var spare: int = main.waiting.size()
	if main.state == main.State.WON:
		return [true, main._stars(), int((main.score - main.wolf_points) / 10000.0)]
	var left := []
	for w in main.get_tree().get_nodes_in_group("wolves"):
		left.append("%s@%s hp%d armor%d" % [w.variant, w.global_position.round(), w.health, w.armor])
	print("   lost %s, left: %s" % [Levels.label(n), ", ".join(left)])
	return [false, 0, 0]


## Whether a kid would click now for this animal's ability, flying at `at`.
static func ability_now(flier, at: Vector2) -> bool:
	var to: Vector2 = at - flier.global_position
	match Catalog.ANIMALS[flier.kind].ability:
		"dash":
			return to.length() < 280.0
		"pound", "egg":
			return absf(to.x) < 30.0
		"split":
			return to.length() < 200.0
		"explode":
			return to.length() < 50.0
		"stampede":
			return to.length() < 380.0 and absf(to.y) < 60.0
	return false


## Searches pulls for the flight that passes closest to the target, preferring flatter shots.
## power: the slingshot's launch speed per pixel of pull (pass sling.POWER).
static func aim(origin: Vector2, at: Vector2, power: float) -> Vector2:
	var best := Vector2(-100, 30)
	var best_score := INF
	for length in [60.0, 75.0, 90.0, 100.0, 110.0]:
		for deg in range(-15, 80):
			var dir := Vector2.from_angle(deg_to_rad(-deg))
			var pull: Vector2 = -dir * length
			var pos: Vector2 = origin + pull
			var vel: Vector2 = -pull * power
			var closest := INF
			var when := 0.0
			for step in 360:
				vel.y += 980.0 / 120.0
				pos += vel / 120.0
				var d := pos.distance_to(at)
				if d < closest:
					closest = d
					when = step / 120.0
				if vel.y > 0.0 and pos.y > at.y + 200.0:
					break
			var score := closest + when * 10.0
			if score < best_score:
				best_score = score
				best = pull
	return best
