extends SceneTree
## Loads every level and checks it stands still on its own (no wolf lost, nothing broken), then
## fires one shot with the animal's ability to exercise the effects. Runs headless and faster
## than real time:
##   godot --headless --fixed-fps 60 --path . --script res://tools/level_check.gd -- [first] [last]
const Levels := preload("res://scripts/levels.gd")


func _initialize() -> void:
	run.call_deferred()


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 1
	var last := int(args[1]) if args.size() > 1 else Levels.COUNT
	var game = root.get_node("Game")
	game.saving = false
	game.unlock_all = true
	var kinds := ["sheep", "goat", "cow", "chicken", "duck", "pig", "bull"]
	var failures := []
	for n in range(first, last + 1):
		game.current_level = n
		# Each level fires a different animal first, so every ability gets used.
		game.lineup[0] = kinds[n % kinds.size()]
		change_scene_to_file("res://scenes/main.tscn")
		await wait_seconds(3.5)
		var main = current_scene
		var wolves: int = main.level.wolves.size()
		var standing: bool = main.wolves_left == wolves and main.score == 0
		print("%s %-20s wolves %d/%d slots %d score %d %s" % [Levels.label(n), main.area.name,
			main.wolves_left, wolves, main.level.slots, main.score, "ok" if standing else "COLLAPSED"])
		if not standing:
			failures.append(n)
		# One shot, using the ability halfway.
		var slingshot = main.slingshot
		if slingshot.animal:
			slingshot.pull = Vector2(-100, 40)
			slingshot._release()
			await wait_seconds(0.5)
			main._try_ability()
			await wait_seconds(2.5)
	print("FAILURES: ", failures)
	quit(failures.size())
