extends Node2D
## Plays one level: builds it from Levels, lines up the player's herd, keeps score, runs the
## camera, and decides win or loss.

const Animal := preload("res://scripts/animal.gd")
const Block := preload("res://scripts/block.gd")
const Wolf := preload("res://scripts/wolf.gd")
const Slingshot := preload("res://scripts/slingshot.gd")
const Hud := preload("res://scripts/hud.gd")
const Background := preload("res://scripts/background.gd")
const Terrain := preload("res://scripts/terrain.gd")
const Pools := preload("res://scripts/pools.gd")
const Trail := preload("res://scripts/trail.gd")
const Debris := preload("res://scripts/debris.gd")
const Effects := preload("res://scripts/effects.gd")
const Levels := preload("res://scripts/levels.gd")
const Areas := preload("res://scripts/areas.gd")
const Catalog := preload("res://scripts/catalog.gd")

const GROUND_Y := Levels.GROUND_Y
const SLINGSHOT_X := Levels.SLING_X
const SPARE_ANIMAL_POINTS := 10000
const VIEW_SIZE := Vector2(1280, 720)

enum State { PLAYING, WON, LOST }

var level: Dictionary
var area: Dictionary
var slingshot: Slingshot
var hud: Hud
var camera: Camera2D
var trail: Trail
var terrain: Terrain
var pools: Pools
var boss: Wolf
## Animals still waiting their turn, lined up behind the slingshot.
var waiting: Array[Animal] = []
## Launched animals (and ducklings) that haven't settled yet.
var in_flight: Array[Animal] = []
## The last animal fired: the one a mid-flight click acts on.
var flier: Animal
var loading := false
var launched_any := false
var state := State.PLAYING
var results_shown := false
var score := 0
## Score when the current shot was fired, to notice a complete miss.
var score_at_launch := 0
var wolves_left := 0
var wolf_points := 0
var block_points := 0
var level_right := 0.0
var level_top := GROUND_Y
var rest_position := VIEW_SIZE / 2.0
var trauma := 0.0
var trail_tick := 0
var base_zoom := 1.0
## Brief zoom-in on big moments, decaying back to 0.
var zoom_kick := 0.0
## Things broken by the current shot, for the combo callouts.
var combo := 0
## Score popups still on screen: [position, seconds left], so new ones stack instead of overlapping.
var recent_popups: Array = []


func _ready() -> void:
	add_to_group("camera_shake")
	Effects.reset_speed()
	level = Levels.build(Game.current_level)
	area = Areas.AREAS[level.area]
	var sky: Array = area.sky
	RenderingServer.set_default_clear_color(sky[1])
	var background := Background.new()
	background.setup(area, Game.current_level)
	add_child(background)
	terrain = Terrain.new()
	terrain.setup(level, area)
	add_child(terrain)
	Debris.floor_at = terrain.floor_y
	pools = Pools.new()
	pools.pools = level.pools
	add_child(pools)
	_build_level()
	trail = Trail.new()
	add_child(trail)
	slingshot = Slingshot.new()
	slingshot.position = Vector2(SLINGSHOT_X, GROUND_Y - level.sling - Slingshot.HEIGHT)
	slingshot.launched.connect(_on_launched)
	add_child(slingshot)
	_build_camera()
	hud = Hud.new()
	hud.slots = level.slots
	hud.retry_pressed.connect(_restart)
	hud.next_pressed.connect(func() -> void: Game.next_after(Game.current_level))
	hud.map_pressed.connect(func() -> void: Game.open_map(level.area, true))
	hud.skip_pressed.connect(func() -> void: Game.skip(Game.current_level))
	hud.herd_changed.connect(_on_herd_changed)
	add_child(hud)
	_line_up_herd()
	_update_hud()
	var title := "%s   %s" % [Levels.label(Game.current_level), area.name]
	if boss:
		title = "Boss: %s!" % Catalog.WOLVES[boss.variant].name
		Sfx.play("boss")
		_wait(1.2).timeout.connect(func() -> void: if is_instance_valid(boss): boss.snarl())
	hud.show_banner(title)
	if Game.announce_animal != "":
		hud.open_herd(Game.announce_animal)
		Game.announce_animal = ""
	_load_next_animal()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_restart()
		elif event.keycode == KEY_ESCAPE:
			if hud.is_menu_open() and not results_shown:
				hud.hide_overlay()
			elif not results_shown:
				hud.show_pause()
		elif event.keycode == KEY_SPACE:
			_try_ability()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_ability()


func _try_ability() -> void:
	if is_instance_valid(flier) and flier.can_use_ability():
		flier.use_ability()
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(flier) and not flier.done and flier.flight_time >= 0.0:
		trail_tick += 1
		if trail_tick % 3 == 0:
			trail.add(flier.global_position)
	if level.pools.is_empty():
		return
	for body in get_tree().get_nodes_in_group("destructible") + get_tree().get_nodes_in_group("herd"):
		var pool := pools.pool_at(body.global_position)
		if pool != "":
			body.sink(pool == "lava")


func _process(delta: float) -> void:
	trauma = maxf(trauma - delta * 1.6, 0.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 24.0 * trauma * trauma
	zoom_kick = maxf(zoom_kick - delta * 0.25, 0.0)
	camera.zoom = Vector2.ONE * base_zoom * (1.0 + zoom_kick)
	for popup in recent_popups:
		popup[1] -= delta
	recent_popups = recent_popups.filter(func(popup: Array) -> bool: return popup[1] > 0.0)
	# Lean toward the animal in flight, then drift back to the full view of the level.
	var target := rest_position
	if is_instance_valid(flier) and not flier.done and flier.flight_time >= 0.0:
		target += ((flier.global_position - rest_position) * 0.3).clamp(Vector2(-60, -160), Vector2(240, 40))
	camera.position = camera.position.lerp(target, 1.0 - exp(-delta * 3.0))
	if is_instance_valid(boss):
		hud.set_boss(Catalog.WOLVES[boss.variant].name, 1.0 - boss.damage_ratio())


## Called through the "camera_shake" group (see Effects.shake).
func shake(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func _build_level() -> void:
	for b in level.blocks:
		var size := Vector2(b[2], b[3])
		var block := Block.new()
		block.configure(size, b[4], b[5])
		block.position = Vector2(b[0], GROUND_Y - b[1] - size.y / 2.0)
		block.destroyed.connect(_on_block_destroyed)
		add_child(block)
		block_points += block.points
		level_right = maxf(level_right, b[0] + size.x / 2.0)
		level_top = minf(level_top, GROUND_Y - b[1] - b[3])
	for w in level.wolves:
		var wolf := Wolf.new()
		wolf.variant = w[2]
		var radius := Catalog.wolf_radius(w[2])
		wolf.position = Vector2(w[0], GROUND_Y - w[1] - radius)
		wolf.destroyed.connect(_on_wolf_destroyed)
		add_child(wolf)
		if wolf.variant == level.boss:
			boss = wolf
		wolves_left += 1
		wolf_points += wolf.points
		level_right = maxf(level_right, w[0] + radius)
		level_top = minf(level_top, GROUND_Y - w[1] - radius * 2.0)


func _build_camera() -> void:
	# Zoom out to fit the whole level (wide or tall), keeping the ground near the bottom edge.
	# The left edge leaves room for a long line of animals behind the slingshot.
	var bottom := GROUND_Y + 80.0
	var left := -40.0 if level.slots > 4 else 0.0
	var needed := Vector2(level_right + 160.0 - left, bottom - (level_top - 90.0))
	var zoom := minf(1.0, minf(VIEW_SIZE.x / needed.x, VIEW_SIZE.y / needed.y))
	var view := VIEW_SIZE / zoom
	rest_position = Vector2(left + view.x / 2.0, bottom - view.y / 2.0)
	camera = Camera2D.new()
	base_zoom = zoom
	camera.zoom = Vector2.ONE * zoom
	camera.position = rest_position
	add_child(camera)
	camera.make_current()


func _line_up_herd() -> void:
	var bounds := Rect2(-300, -3000, level_right + 900, 3000 + GROUND_Y + 300)
	var herd := Game.lineup_for(level.slots)
	for i in herd.size():
		var animal := Animal.new()
		animal.kind = herd[i]
		animal.display_only = true
		animal.bounds = bounds
		animal.position = _herd_slot(i, animal.kind)
		animal.settled.connect(_on_animal_settled)
		animal.spawned.connect(_on_duckling_spawned)
		add_child(animal)
		waiting.append(animal)


## The herd was edited before the first shot: swap in the new lineup.
func _on_herd_changed() -> void:
	if launched_any or state != State.PLAYING:
		return
	var loaded := slingshot.unload()
	if loaded:
		loaded.queue_free()
	for animal in waiting:
		animal.queue_free()
	waiting.clear()
	_line_up_herd()
	if not loading:
		_load_next_animal()


## Hops the next animal in line up into the slingshot.
func _load_next_animal() -> void:
	if waiting.is_empty() or state != State.PLAYING:
		return
	loading = true
	var animal: Animal = waiting[0]
	var start := animal.global_position
	var end := slingshot.global_position
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(animal):
			animal.global_position = start.lerp(end, t) + Vector2(0, -sin(t * PI) * 70.0),
		0.0, 1.0, 0.45)
	await tween.finished
	loading = false
	if not is_instance_valid(animal) or not animal in waiting:
		# The herd was swapped mid-hop.
		if not waiting.is_empty() and slingshot.animal == null:
			_load_next_animal()
		return
	waiting.erase(animal)
	# The rest of the line shuffles up.
	for i in waiting.size():
		create_tween().tween_property(waiting[i], "global_position", _herd_slot(i, waiting[i].kind), 0.3).set_delay(i * 0.06)
	animal.set_collidable(true)
	slingshot.load_animal(animal)
	hud.set_hint(animal.hint())


func _herd_slot(index: int, kind: String) -> Vector2:
	return Vector2(SLINGSHOT_X - 58 - index * 38, GROUND_Y - level.sling - Animal.RADIUS * Catalog.animal_size(kind))


func _update_hud() -> void:
	hud.set_status("%s   Score: %d   Wolves: %d" % [Levels.label(Game.current_level), score, wolves_left])


func _on_launched(animal: Animal) -> void:
	in_flight.append(animal)
	flier = animal
	trail.clear()
	launched_any = true
	score_at_launch = score
	combo = 0
	hud.show_herd_button(false)


func _on_duckling_spawned(chick: Animal) -> void:
	chick.settled.connect(_on_animal_settled)
	in_flight.append(chick)


func _on_animal_settled(animal: Animal) -> void:
	in_flight.erase(animal)
	await _wait(0.6).timeout
	if is_instance_valid(animal):
		if animal.bounds.has_point(animal.global_position):
			animal.poof()
		animal.queue_free()
	if state != State.PLAYING or loading or not in_flight.is_empty() or slingshot.animal != null:
		return
	if score == score_at_launch:
		_wolves_laugh()
	if not waiting.is_empty():
		_load_next_animal()
		return
	# Out of animals: give falling pieces a moment to finish the job.
	await _wait(2.5).timeout
	if state == State.PLAYING and in_flight.is_empty():
		_lose()


func _wolves_laugh() -> void:
	Sfx.play("laugh", -4.0, 1.0, 2000)
	for wolf in get_tree().get_nodes_in_group("wolves"):
		wolf.laugh()


func _on_block_destroyed(block: Block) -> void:
	_add_score(block.points, block.global_position, Color(1.0, 0.95, 0.65), 20)
	Effects.shake(self, 0.25 if block.kind in ["stone", "metal"] else 0.12)
	_count_combo()


func _on_wolf_destroyed(wolf: Wolf) -> void:
	wolves_left -= 1
	_add_score(wolf.points, wolf.global_position + Vector2(0, -24), Color(1.0, 0.6, 0.2), 34 if not wolf.is_boss else 44)
	Effects.shake(self, 0.8 if wolf.is_boss else 0.35)
	_count_combo()
	if wolves_left == 0 and state == State.PLAYING:
		# The last wolf goes down in slow motion.
		Effects.slow_motion(self, 0.3, 1.0)
		zoom_kick = 0.08
	else:
		Effects.hitstop(self, 0.12 if wolf.is_boss else 0.07)
		zoom_kick = maxf(zoom_kick, 0.03)
	if wolf == boss:
		hud.set_boss("", 0.0)
	if wolves_left == 0 and state == State.PLAYING:
		_win()


func _add_score(points: int, pos: Vector2, color: Color, font_size := 24) -> void:
	if results_shown or state == State.LOST:
		return
	score += points
	# Nudge it up past any popup still showing nearby.
	var moved := true
	while moved:
		moved = false
		for popup in recent_popups:
			var other: Vector2 = popup[0]
			if absf(other.x - pos.x) < 70.0 and absf(other.y - pos.y) < font_size + 4.0:
				pos.y = other.y - font_size - 4.0
				moved = true
	recent_popups.append([pos, 0.7])
	Effects.popup(self, pos, str(points), color, font_size)
	_update_hud()


## Cheers when one shot wrecks a lot.
func _count_combo() -> void:
	if state != State.PLAYING or not launched_any:
		return
	combo += 1
	var cheers := {4: "Nice!", 8: "Great!", 12: "Wrecked!", 18: "Mega Wreck!", 25: "Total Chaos!"}
	if cheers.has(combo):
		var at := camera.get_screen_center_position() + Vector2(0, -170) / base_zoom
		Effects.popup(self, at, cheers[combo], Color(1.0, 0.85, 0.2), int(40 / base_zoom))
		Sfx.play("ability", -6.0, 1.0 + combo * 0.02)


func _win() -> void:
	state = State.WON
	slingshot.enabled = false
	hud.set_hint("")
	hud.show_herd_button(false)
	# Let the wreckage finish falling (it still scores), then cash in the spare animals.
	await _wait(1.8).timeout
	var spares: Array[Animal] = []
	var loaded := slingshot.unload()
	if loaded:
		spares.append(loaded)
	spares.append_array(waiting)
	waiting.clear()
	for animal in spares:
		await _wait(0.35).timeout
		if is_instance_valid(animal):
			_add_score(SPARE_ANIMAL_POINTS, animal.global_position + Vector2(0, -36), Color(0.6, 1.0, 0.6), 30)
			animal.poof()
			animal.queue_free()
	await _wait(0.6).timeout
	results_shown = true
	var stars := _stars()
	var is_best := Game.record(Game.current_level, score, stars)
	Sfx.play("win")
	hud.show_results(true, score, stars, Game.best_score(Game.current_level), is_best, true)


func _lose() -> void:
	state = State.LOST
	results_shown = true
	slingshot.enabled = false
	hud.set_hint("")
	_wolves_laugh()
	Sfx.play("lose")
	var tries := Game.record_loss(Game.current_level)
	hud.show_results(false, score, 0, Game.best_score(Game.current_level), false, false, tries >= 2)


## One star for winning, more for wrecking the place and keeping animals spare.
func _stars() -> int:
	var two := wolf_points + int(block_points * 0.3)
	return 1 + int(score >= two) + int(score >= two + SPARE_ANIMAL_POINTS)


func _restart() -> void:
	get_tree().reload_current_scene()


## A one-shot timer owned by this node, so a pending wait dies quietly when the scene changes.
## Await its timeout signal.
func _wait(seconds: float) -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	add_child(timer)
	timer.start()
	timer.timeout.connect(timer.queue_free)
	return timer
