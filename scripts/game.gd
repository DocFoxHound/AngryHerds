extends Node
## Progress and flow between screens: which level is being played, best scores and stars,
## the player's herd lineup, which stories have been seen, and moving between the title, map,
## stories and levels. Progress lives in one of three save slots and is saved as you play.

const Catalog := preload("res://scripts/catalog.gd")
const Levels := preload("res://scripts/levels.gd")

const SLOTS := 3
const SETTINGS_PATH := "user://settings.cfg"
const TITLE_SCENE := "res://scenes/title.tscn"
const MAP_SCENE := "res://scenes/map.tscn"
const LEVEL_SCENE := "res://scenes/main.tscn"
const STORY_SCENE := "res://scenes/story.tscn"
## Story index played after the last level.
const ENDING := 10

## Save slot in use, 1..SLOTS.
var slot := 1
var sound_on := true
## Level being played, 1..100.
var current_level := 1
var lineup: Array = []
var best_scores := {}
var best_stars := {}
var seen_stories: Array = []
## Levels passed with the Skip button: they unlock the next level but earn no stars.
var skipped: Array = []
## Losses per level this session; after two, the results card offers Skip.
var losses := {}
## Tools that play levels automatically turn this off so they don't touch the player's progress.
var saving := true
## Run with `-- --unlock-all` to open every level and animal (for testing).
var unlock_all := false
## Area the map should reveal with an animation (just unlocked), or -1.
var reveal_area := -1
## Area the map should centre on and open.
var map_area := 0
var map_open_panel := false
## Story being shown, and the level to start after it (0: back to the map).
var story_index := 0
var story_then_level := 0
## Animal to introduce on the herd screen when the level starts, or "".
var announce_animal := ""


func _ready() -> void:
	unlock_all = "--unlock-all" in OS.get_cmdline_user_args()
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		set_sound(settings.get_value("audio", "sound", true))
	load_slot(1)


func slot_path(n: int) -> String:
	return "user://save_%d.cfg" % n


## Switches to a save slot, loading its progress (an unused slot starts fresh).
func load_slot(n: int) -> void:
	slot = n
	lineup = []
	for i in Catalog.LINEUP_SIZE:
		lineup.append("sheep")
	best_scores = {}
	best_stars = {}
	seen_stories = []
	skipped = []
	losses = {}
	reveal_area = -1
	var config := ConfigFile.new()
	if config.load(slot_path(n)) == OK:
		for section in config.get_sections():
			if section.begins_with("lvl_"):
				var level := int(section.trim_prefix("lvl_"))
				best_scores[level] = int(config.get_value(section, "score", 0))
				best_stars[level] = int(config.get_value(section, "stars", 0))
		var saved_lineup: Array = config.get_value("herd", "lineup", [])
		for i in mini(saved_lineup.size(), Catalog.LINEUP_SIZE):
			lineup[i] = saved_lineup[i]
		seen_stories = config.get_value("story", "seen", [])
		skipped = config.get_value("story", "skipped", [])
	map_area = Levels.area_of(maxi(highest_unlocked(), 1))


## What the title screen shows for a slot: whether it's in use, how far it got, stars won.
func slot_summary(n: int) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(slot_path(n)) != OK:
		return {"used": false}
	var stars := 0
	var furthest := 1
	for section in config.get_sections():
		if section.begins_with("lvl_"):
			var level_stars := int(config.get_value(section, "stars", 0))
			stars += level_stars
			if level_stars > 0:
				furthest = maxi(furthest, mini(int(section.trim_prefix("lvl_")) + 1, Levels.COUNT))
	return {"used": true, "stars": stars, "level": furthest}


func delete_slot(n: int) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(n)))
	if n == slot:
		load_slot(n)


func set_sound(on: bool) -> void:
	sound_on = on
	AudioServer.set_bus_mute(0, not on)
	var settings := ConfigFile.new()
	settings.set_value("audio", "sound", on)
	settings.save(SETTINGS_PATH)


# -- Progress --------------------------------------------------------------------------------

## Saves a won level's result. Returns true if it beats the previous best score.
func record(level: int, score: int, stars: int) -> bool:
	var first_clear := not is_passed(level)
	var is_best: bool = score > best_scores.get(level, -1)
	if is_best:
		best_scores[level] = score
	best_stars[level] = maxi(stars, stars_for(level))
	if first_clear and level % Levels.PER_AREA == 0 and level < Levels.COUNT:
		reveal_area = level / Levels.PER_AREA
	_save()
	return is_best


func stars_for(level: int) -> int:
	return best_stars.get(level, 0)


func best_score(level: int) -> int:
	return best_scores.get(level, 0)


func is_unlocked(level: int) -> bool:
	return unlock_all or level == 1 or is_passed(level - 1)


func is_passed(level: int) -> bool:
	return stars_for(level) > 0 or level in skipped


func record_loss(level: int) -> int:
	losses[level] = losses.get(level, 0) + 1
	return losses[level]


## Gives up on a level: the next one unlocks (and a new area, after a boss), with no stars.
func skip(level: int) -> void:
	if not is_passed(level):
		skipped.append(level)
		if level % Levels.PER_AREA == 0 and level < Levels.COUNT:
			reveal_area = level / Levels.PER_AREA
	_save()
	next_after(level)


func highest_unlocked() -> int:
	for level in range(1, Levels.COUNT + 1):
		if not is_unlocked(level):
			return level - 1
	return Levels.COUNT


func is_area_unlocked(area: int) -> bool:
	return is_unlocked(area * Levels.PER_AREA + 1)


func area_stars(area: int) -> int:
	var total := 0
	for i in Levels.PER_AREA:
		total += stars_for(area * Levels.PER_AREA + i + 1)
	return total


func total_stars() -> int:
	var total := 0
	for level in best_stars:
		total += best_stars[level]
	return total


func is_animal_unlocked(kind: String) -> bool:
	return highest_unlocked() >= int(Catalog.ANIMALS[kind].unlock)


## The first `count` animals of the lineup, with anything not yet unlocked swapped for a sheep.
func lineup_for(count: int) -> Array:
	var herd := []
	for i in count:
		var kind: String = lineup[i] if i < lineup.size() else "sheep"
		herd.append(kind if is_animal_unlocked(kind) else "sheep")
	return herd


func set_lineup_slot(index: int, kind: String) -> void:
	lineup[index] = kind
	_save()


func _save() -> void:
	if not saving:
		return
	var config := ConfigFile.new()
	for level in best_scores:
		config.set_value("lvl_%d" % level, "score", best_scores[level])
		config.set_value("lvl_%d" % level, "stars", stars_for(level))
	config.set_value("herd", "lineup", lineup)
	config.set_value("story", "seen", seen_stories)
	config.set_value("story", "skipped", skipped)
	config.save(slot_path(slot))


# -- Moving between screens ------------------------------------------------------------------

## Starts a level, playing its area's story first if this is the first visit.
## Starts (or continues) the game in the current slot: the map, or the opening story.
func start() -> void:
	if not 0 in seen_stories:
		play_level(1)
	else:
		_save()
		open_map(map_area)


func play_level(level: int) -> void:
	current_level = clampi(level, 1, Levels.COUNT)
	var area := Levels.area_of(current_level)
	if (current_level - 1) % Levels.PER_AREA == 0 and not area in seen_stories:
		play_story(area, current_level)
		return
	get_tree().change_scene_to_file(LEVEL_SCENE)


func play_story(index: int, then_level := 0) -> void:
	story_index = index
	story_then_level = then_level
	get_tree().change_scene_to_file(STORY_SCENE)


func story_finished() -> void:
	if not story_index in seen_stories:
		seen_stories.append(story_index)
		_save()
	if story_then_level > 0:
		current_level = story_then_level
		var kind := Catalog.animal_unlocked_at(current_level)
		if kind != "" and kind != "sheep":
			announce_animal = kind
		get_tree().change_scene_to_file(LEVEL_SCENE)
	else:
		open_map(map_area)


func open_map(area := -1, open_panel := false) -> void:
	if area >= 0:
		map_area = area
	map_open_panel = open_panel
	get_tree().change_scene_to_file(MAP_SCENE)


## Where "Next" goes after winning a level.
func next_after(level: int) -> void:
	if level >= Levels.COUNT:
		play_story(ENDING)
	elif level % Levels.PER_AREA == 0:
		open_map(Levels.area_of(level + 1))
	else:
		play_level(level + 1)
