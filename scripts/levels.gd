## The 100 levels: ten areas of ten. A level is generated from its number, so the same number
## always gives the same layout: prefab structures (huts, towers, barns, ships, ...) placed on
## terrain shaped by the area's style. Heights are measured upward from GROUND_Y.
##
## Levels.build(number) returns:
##   ground: PackedVector2Array, the terrain's top edge in world coordinates, left to right
##   pools: [[x0, x1, surface_height, "water" or "lava"]]
##   platforms: [[x_center, top_height, width]], static ledges in the area's platform look
##   blocks: [[x, bottom, width, height, material, shape]], shape is rect, tri or circle
##   wolves: [[x, bottom, variant]]
##   sling: ground height at the slingshot, slots: herd size, boss: boss variant or ""

const Areas := preload("res://scripts/areas.gd")
const Catalog := preload("res://scripts/catalog.gd")

const GROUND_Y := 640.0
const COUNT := 100
const PER_AREA := 10
const SLING_X := 220.0
const SLING_FLAT_END := 380.0
const FIRST_X := 600.0
## Structures stay left of this so every target is within slingshot range.
const MAX_RIGHT := 1420.0
const LEFT_EDGE := -1600.0
const RIGHT_EDGE := 3600.0

## Structure kinds each terrain style uses. The first two are the simple ones used early on.
const STYLE_PREFABS := {
	"farm": ["hut", "barn", "crates", "wall", "twin", "tower"],
	"forest": ["hut", "tower", "twin", "pyramid", "bridge", "wall"],
	"river": ["hut", "twin", "crates", "tower", "bridge"],
	"canyon": ["hut", "wall", "twin", "tower", "bunker", "pyramid"],
	"peaks": ["igloo", "hut", "tower", "crates", "pyramid"],
	"beach": ["ship", "hut", "crates", "tower", "ship"],
	"city": ["skyscraper", "twin", "skyscraper", "crates", "tower"],
	"graveyard": ["tombs", "hut", "twin", "pyramid", "tower"],
	"volcano": ["bunker", "hut", "tower", "twin", "pyramid", "wall"],
	"castle": ["keep", "tower", "bunker", "pyramid", "wall"],
}
## How much the ground between flat spots wobbles, per style.
const BUMPS := {"farm": 10.0, "forest": 30.0, "river": 10.0, "canyon": 25.0, "peaks": 45.0,
	"beach": 0.0, "city": 0.0, "graveyard": 22.0, "volcano": 28.0, "castle": 12.0}

var rng := RandomNumberGenerator.new()
var area: Dictionary
var area_index := 0
## Level within the area, 0..9.
var t := 0


static func area_of(number: int) -> int:
	return (number - 1) / PER_AREA


static func label(number: int) -> String:
	return "%d-%d" % [area_of(number) + 1, (number - 1) % PER_AREA + 1]


static func build(number: int) -> Dictionary:
	var generator = load("res://scripts/levels.gd").new()
	return generator._generate(clampi(number, 1, COUNT))


func _generate(number: int) -> Dictionary:
	rng.seed = number * 7919 + 1013
	area_index = area_of(number)
	t = (number - 1) % PER_AREA
	area = Areas.AREAS[area_index]
	var style: String = area.style
	var boss: String = area.boss if t == PER_AREA - 1 else ""
	var pieces := _choose_pieces(number, boss)

	# Keep everything in range: drop structures (never the boss fort) until it fits.
	var start := 690.0 if style in ["river", "castle", "beach"] else FIRST_X
	var total := 0.0
	for p in pieces:
		total += p.w
	while pieces.size() > 1 and total + 60.0 * (pieces.size() - 1) > MAX_RIGHT - start:
		var drop: Dictionary = pieces.pop_front() if boss != "" else pieces.pop_back()
		total -= drop.w
	var slack := maxf(MAX_RIGHT - start - total - 60.0 * (pieces.size() - 1), 0.0)
	var x := start + rng.randf_range(0.0, minf(160.0, slack * 0.4))
	slack = maxf(MAX_RIGHT - x - total - 60.0 * (pieces.size() - 1), 0.0)
	var sling_h := _sling_height(style)

	# Decide where each structure stands: on its own patch of flat ground or on a platform.
	var placed := []
	var highest_flat := sling_h
	for p in pieces:
		var spot := {"piece": p, "x": x, "h": _ground_height(style), "platform": _wants_platform(style, p)}
		if not spot.platform:
			highest_flat = maxf(highest_flat, spot.h)
		placed.append(spot)
		var gap := 60.0
		if pieces.size() > 1:
			gap += slack / (pieces.size() - 1) * rng.randf_range(0.3, 0.9)
		x += p.w + gap

	var level := {"blocks": [], "wolves": [], "platforms": [], "pools": [], "boss": boss,
		"sling": sling_h, "area": area_index, "number": number}
	var flats := [[LEFT_EDGE, SLING_FLAT_END, sling_h]]
	var right := 0.0
	for spot in placed:
		var p: Dictionary = spot.piece
		var base: float = spot.h
		if spot.platform:
			base = maxf(highest_flat + 30.0, _platform_height(style))
			level.platforms.append([spot.x + p.w / 2.0, base, p.w + 16.0])
		# The ground under a platform is kept flat and low too, so it never pokes through.
		flats.append([spot.x - 25.0, spot.x + p.w + 25.0, spot.h])
		for b in p.blocks:
			level.blocks.append([spot.x + b[0], base + b[1], b[2], b[3], b[4], b[5]])
		for w in p.wolves:
			level.wolves.append([spot.x + w[0], base + w[1], w[2]])
		right = spot.x + p.w
	flats.append([right + rng.randf_range(140.0, 260.0), RIGHT_EDGE, _tail_height(style)])
	_build_ground(level, flats, style)

	# Keep the wolf count fair for the herd size: empty some rooms if there are too many.
	var cap := 3 + t / 3 + area_index / 4
	while level.wolves.size() > cap:
		var i := rng.randi_range(0, level.wolves.size() - 1)
		if level.wolves[i][2] != boss:
			level.wolves.remove_at(i)
	var wolf_count: int = level.wolves.size()
	level.slots = clampi(int(ceil(wolf_count * 0.6)) + 2 + (1 if boss != "" else 0), 3, Catalog.LINEUP_SIZE)
	return level


func _choose_pieces(number: int, boss: String) -> Array:
	if number == 1:
		return [_hut("wood", ["wolf"], "", "")]
	if number == 2:
		return [_hut("wood", ["wolf"], "wolf", "wolf")]
	var list := []
	if boss != "":
		if area_index >= 2:
			list.append(_structure())
		list.append(_fort(boss))
		return list
	var count := 1
	if t >= 1:
		count = rng.randi_range(1, 2)
	if t >= 3:
		count = 2
	if t >= 6:
		count = rng.randi_range(2, 3)
	for i in count:
		list.append(_structure())
	if t >= 1 and rng.randf() < 0.6:
		list.insert(rng.randi_range(0, list.size()), _prop())
	return list


func _structure() -> Dictionary:
	var kinds: Array = STYLE_PREFABS[area.style]
	var kind: String = kinds[rng.randi_range(0, 1)] if t < 3 else kinds[rng.randi_range(0, kinds.size() - 1)]
	var mat := _mat()
	var floors := rng.randi_range(1, _max_floors())
	match kind:
		"tower":
			return _with_top(_hut(mat, _wolf_list(maxi(2, floors)), "", ""))
		"twin":
			var p := _twin(mat, _wolf(), _maybe_wolf(0.7))
			return _stack(p, _with_top(_hut(_mat(), _wolf_list(1), "", ""))) if rng.randf() < 0.3 + t * 0.06 else p
		"pyramid":
			var p := _twin(mat, _wolf(), _wolf())
			p = _stack(p, _with_top(_hut(_mat(), _wolf_list(1), "", "")))
			return p
		"barn":
			var barn := _hut("redwood", _wolf_list(mini(floors, 2)), "", "redwood")
			var p := _piece(barn.w + 46.0)
			_merge(p, barn, 0.0, 0.0)
			_blk(p, barn.w + 23.0, 0.0, 38.0, 38.0, "hay", "circle")
			p.flat_top = false
			return p
		"crates":
			return _crates(mat)
		"wall":
			return _wall(mat)
		"bridge":
			return _bridge(mat, floors)
		"bunker":
			var hard := "metal" if area_index >= 8 else "stone"
			var p := _twin(hard, _wolf(), _wolf())
			return _stack(p, _with_top(_hut(hard, _wolf_list(1), "", ""))) if t >= 5 else p
		"igloo":
			return _hut("ice", _wolf_list(mini(floors, 2)), "", "ice")
		"ship":
			var hull := _twin("redwood", _wolf(), _maybe_wolf(0.6), "wood")
			var cabin := _hut("wood", [_wolf()], "", "cloth")
			return _stack(hull, cabin)
		"skyscraper":
			var glass := "glass" if rng.randf() < 0.7 else mat
			return _with_top(_hut(glass, _wolf_list(maxi(2, floors + 1)), "", "", "metal" if rng.randf() < 0.5 else "stone"))
		"tombs":
			return _tombs()
		"keep":
			var p := _twin("stone", _wolf(), _wolf())
			return _stack(p, _hut("stone", _wolf_list(1), "", "redwood"))
	return _with_top(_hut(mat, _wolf_list(floors), "", ""))


## The boss's hall: one tall room with a guard post on top.
func _fort(boss: String) -> Dictionary:
	var mat := "wood" if area_index < 3 else "stone"
	var hall := _hut(mat, [boss], "", "")
	var guard := _hut(_mat(), [_wolf()] if area_index >= 1 else [""], "", _roof_mat())
	return _stack(hall, guard)


## Something to knock over that isn't hiding a wolf: hay bales, boulders, crates, tombstones.
func _prop() -> Dictionary:
	var p := _piece(44.0)
	match area.style:
		"farm":
			_blk(p, 22.0, 0.0, 38.0, 38.0, "hay", "circle")
		"canyon", "volcano":
			_blk(p, 22.0, 0.0, 40.0, 40.0, "stone", "circle")
		"peaks":
			_blk(p, 22.0, 0.0, 36.0, 36.0, "ice", "circle")
		"graveyard":
			_blk(p, 22.0, 0.0, 26.0, 50.0, "stone")
		"forest", "castle":
			_blk(p, 22.0, 0.0, 34.0, 34.0, "wood", "circle")
		_:
			_blk(p, 22.0, 0.0, 36.0, 36.0, "wood")
	p.flat_top = false
	return p


# -- Prefab building blocks ------------------------------------------------------------------

func _piece(w: float) -> Dictionary:
	return {"w": w, "top": 0.0, "h": 0.0, "blocks": [], "wolves": [], "flat_top": true}


func _blk(p: Dictionary, x: float, b: float, w: float, h: float, mat: String, shape := "rect") -> void:
	p.blocks.append([x, b, w, h, mat, shape])
	p.h = maxf(p.h, b + h)


func _put_wolf(p: Dictionary, x: float, b: float, variant: String) -> void:
	p.wolves.append([x, b, variant])
	p.h = maxf(p.h, b + _diam(variant))


func _merge(dst: Dictionary, src: Dictionary, dx: float, db: float) -> void:
	for b in src.blocks:
		dst.blocks.append([b[0] + dx, b[1] + db, b[2], b[3], b[4], b[5]])
	for w in src.wolves:
		dst.wolves.append([w[0] + dx, w[1] + db, w[2]])
	dst.h = maxf(dst.h, src.h + db)


## Puts upper centered on lower's flat top.
func _stack(lower: Dictionary, upper: Dictionary) -> Dictionary:
	if not lower.flat_top or upper.w > lower.w:
		return lower
	_merge(lower, upper, (lower.w - upper.w) / 2.0, lower.top)
	lower.top += upper.top
	lower.flat_top = upper.flat_top
	return lower


## Posts and slabs, one room per floor (wolf variant or "" for an empty room). roof is "" (flat,
## stackable), "wolf" (top_wolf stands on it) or a material for a triangular roof.
func _hut(mat: String, floors: Array, top_wolf: String, roof: String, slab_mat := "") -> Dictionary:
	var room := _room(floors + [top_wolf])
	var post := _post_w(mat)
	var slab := slab_mat if slab_mat != "" else _slab_of(mat)
	var w := room + post * 2.0 + 10.0
	var p := _piece(w)
	var b := 0.0
	for v in floors:
		_blk(p, 5.0 + post / 2.0, b, post, room, mat)
		_blk(p, w - 5.0 - post / 2.0, b, post, room, mat)
		if v != "":
			_put_wolf(p, w / 2.0, b, v)
		b += room
		var thick := _slab_t(slab)
		_blk(p, w / 2.0, b, w, thick, slab)
		b += thick
	p.top = b
	if roof == "wolf":
		_put_wolf(p, w / 2.0, b, top_wolf)
		p.flat_top = false
	elif roof != "":
		_blk(p, w / 2.0, b, w, rng.randf_range(32.0, 46.0), roof, "tri")
		p.flat_top = false
	return p


## Gives a stackable hut a wolf on the roof or a pointed roof, sometimes.
func _with_top(p: Dictionary) -> Dictionary:
	if not p.flat_top:
		return p
	var roll := rng.randf()
	if roll < 0.45:
		var v := _wolf()
		if _diam(v) < p.w:
			_put_wolf(p, p.w / 2.0, p.top, v)
			p.flat_top = false
	elif roll < 0.75:
		_blk(p, p.w / 2.0, p.top, p.w, rng.randf_range(32.0, 46.0), _roof_mat(), "tri")
		p.flat_top = false
	return p


## Two rooms side by side under one slab.
func _twin(mat: String, a: String, b: String, slab_mat := "") -> Dictionary:
	var room := _room([a, b])
	var post := _post_w(mat)
	var slab := slab_mat if slab_mat != "" else _slab_of(mat)
	var w := room * 2.0 + post * 3.0 + 10.0
	var p := _piece(w)
	var x := 5.0 + post / 2.0
	var rooms := [a, b]
	for i in 3:
		_blk(p, x, 0.0, post, room, mat)
		if i < 2 and rooms[i] != "":
			_put_wolf(p, x + post / 2.0 + room / 2.0, 0.0, rooms[i])
		x += post + room
	var thick := _slab_t(slab)
	_blk(p, w / 2.0, room, w, thick, slab)
	p.top = room + thick
	return p


## A little pyramid of boxes with a wolf on top.
func _crates(mat: String) -> Dictionary:
	var rows := 2 if t < 4 else 3
	var size := 42.0 if mat != "stone" else 38.0
	var step := size + 2.0
	var p := _piece(rows * step)
	for row in rows:
		for i in rows - row:
			_blk(p, step * (row / 2.0 + i) + step / 2.0, row * size, size, size, mat)
	_put_wolf(p, p.w / 2.0, rows * size, _wolf())
	p.flat_top = false
	return p


## A tall wall with a wolf hiding behind it, sometimes a second wall too.
func _wall(mat: String) -> Dictionary:
	var v := _wolf()
	var thick := _post_w(mat) + 4.0
	var height := rng.randf_range(90.0, 110.0 + t * 10.0)
	var walls := 2 if rng.randf() < 0.4 else 1
	var gap := _diam(v) + 30.0
	var p := _piece(thick * walls + gap * walls)
	_blk(p, thick / 2.0, 0.0, thick, height, mat)
	_put_wolf(p, thick + gap / 2.0, 0.0, v)
	if walls == 2:
		_blk(p, thick * 1.5 + gap, 0.0, thick, height * 0.8, mat)
		_put_wolf(p, thick * 2.0 + gap * 1.5, 0.0, _wolf())
	p.flat_top = false
	return p


## Two matching towers joined by a plank, with a wolf standing on it.
func _bridge(mat: String, floors: int) -> Dictionary:
	var list := _wolf_list(floors)
	var a := _hut(mat, list, "", "")
	var b := _hut(mat, list, "", "")
	var gap := rng.randf_range(50.0, 90.0)
	var p := _piece(a.w * 2.0 + gap)
	_merge(p, a, 0.0, 0.0)
	_merge(p, b, a.w + gap, 0.0)
	var slab := _slab_of(mat)
	_blk(p, a.w + gap / 2.0, a.top, gap + 40.0, _slab_t(slab), slab)
	_put_wolf(p, a.w + gap / 2.0, a.top + _slab_t(slab), _wolf())
	p.flat_top = false
	return p


## Tombstones with wolves lurking between them.
func _tombs() -> Dictionary:
	var count := rng.randi_range(2, 3)
	var variants := []
	for i in count:
		variants.append(_wolf())
	var room := _room(variants)
	var p := _piece(count * room + (count + 1) * 24.0)
	var x := 12.0
	for i in count + 1:
		_blk(p, x, 0.0, 24.0, rng.randf_range(48.0, 64.0), "stone")
		if i < count:
			_put_wolf(p, x + 12.0 + room / 2.0, 0.0, variants[i])
		x += 24.0 + room
	p.flat_top = false
	return p


# -- Choices ---------------------------------------------------------------------------------

func _mat() -> String:
	var hard_chance := clampf(t * 0.06 + area_index * 0.03, 0.0, 0.6)
	var pool: Array = area.hard_mats if rng.randf() < hard_chance else area.mats
	return pool[rng.randi_range(0, pool.size() - 1)]


func _roof_mat() -> String:
	match area.style:
		"farm", "castle", "forest":
			return "redwood"
		"peaks":
			return "ice"
		"beach":
			return "cloth"
		"city":
			return "glass"
	return _slab_of(_mat())


func _wolf() -> String:
	if area_index == 0 and t < 2:
		return "wolf"
	var pool: Array = area.wolves if t < 5 else area.late_wolves
	var v: String = pool[rng.randi_range(0, pool.size() - 1)]
	if (v == "big" or v == "captain") and t < 4:
		v = pool[0]
	return v


func _maybe_wolf(chance: float) -> String:
	return _wolf() if rng.randf() < chance else ""


## A wolf for each floor; upper floors are sometimes empty, the ground floor never.
func _wolf_list(floors: int) -> Array:
	var list := []
	for i in floors:
		list.append(_wolf() if i == 0 or rng.randf() < 0.8 else "")
	return list


func _max_floors() -> int:
	return mini(1 + int(t >= 3) + int(t >= 6) + int(area_index >= 4 and t >= 4), 4)


func _room(variants: Array) -> float:
	var room := 44.0
	for v in variants:
		if v != "":
			room = maxf(room, _diam(v) + 14.0)
	return room


func _diam(variant: String) -> float:
	return Catalog.wolf_radius(variant) * 2.0


func _post_w(mat: String) -> float:
	return {"stone": 26.0, "metal": 18.0}.get(mat, 20.0)


func _slab_t(mat: String) -> float:
	return {"stone": 24.0, "metal": 16.0}.get(mat, 20.0)


func _slab_of(mat: String) -> String:
	return "wood" if mat in ["hay", "cloth", "redwood"] else mat


# -- Terrain ---------------------------------------------------------------------------------

func _sling_height(style: String) -> float:
	match style:
		"forest":
			return rng.randf_range(0.0, 30.0)
		"river":
			return 15.0
		"canyon":
			return rng.randf_range(0.0, 40.0) + t * 4.0
		"peaks":
			return rng.randf_range(100.0, 150.0)
		"beach":
			return 25.0
		"graveyard":
			return 10.0
		"volcano":
			return 30.0
		"castle":
			return 20.0
	return 0.0


func _ground_height(style: String) -> float:
	match style:
		"farm":
			return rng.randf_range(15.0, 35.0) if t >= 4 and rng.randf() < 0.35 else 0.0
		"forest":
			return rng.randf_range(0.0, 20.0 + t * 10.0)
		"river":
			return rng.randf_range(0.0, 20.0)
		"canyon":
			return rng.randf_range(0.0, 30.0)
		"peaks":
			return rng.randf_range(30.0, 80.0 + t * 18.0)
		"beach":
			return 6.0
		"graveyard":
			return rng.randf_range(0.0, 15.0 + t * 6.0)
		"volcano":
			return rng.randf_range(10.0, 40.0 + t * 10.0)
		"castle":
			return rng.randf_range(0.0, 20.0)
	return 0.0


func _wants_platform(style: String, p: Dictionary) -> bool:
	if p.wolves.is_empty():
		return false
	match style:
		"canyon":
			return rng.randf() < 0.35 + t * 0.05
		"beach":
			return rng.randf() < 0.25 + t * 0.04
		"city":
			return rng.randf() < 0.3 + t * 0.06
		"volcano":
			return rng.randf() < 0.25
		"castle":
			return rng.randf() < 0.45 + t * 0.05
		"forest":
			return t >= 5 and rng.randf() < 0.25
	return false


func _platform_height(style: String) -> float:
	match style:
		"city":
			return rng.randf_range(60.0, 90.0 + t * 18.0)
		"beach":
			return rng.randf_range(50.0, 80.0)
		"forest":
			return rng.randf_range(50.0, 90.0)
	return rng.randf_range(50.0, 80.0 + t * 12.0)


func _tail_height(style: String) -> float:
	match style:
		"peaks":
			return rng.randf_range(120.0, 260.0)
		"canyon":
			return rng.randf_range(60.0, 140.0)
		"beach":
			return 20.0
	return rng.randf_range(0.0, 50.0)


func _pool_between(style: String, index: int, width: float) -> String:
	if not area.has("pool") or width < 90.0:
		return ""
	match style:
		"river":
			return area.pool if index == 0 or rng.randf() < 0.5 else ""
		"beach":
			return area.pool
		"castle":
			return area.pool if index == 0 else ""
		"volcano":
			return area.pool if rng.randf() < 0.6 else ""
	return ""


## Joins the flat spots into one ground line, with bumps, dips and pools in the gaps.
func _build_ground(level: Dictionary, flats: Array, style: String) -> void:
	var amp: float = BUMPS[style]
	var points := PackedVector2Array()
	for i in flats.size():
		var f: Array = flats[i]
		points.append(Vector2(f[0], GROUND_Y - f[2]))
		points.append(Vector2(f[1], GROUND_Y - f[2]))
		if i + 1 == flats.size():
			break
		var g: Array = flats[i + 1]
		var x0: float = f[1]
		var x1: float = g[0]
		if x1 - x0 < 2.0:
			continue
		var pool := _pool_between(style, i, x1 - x0)
		var surface: float = 0.0 if style == "beach" else minf(f[2], g[2]) - 14.0
		if pool != "":
			level.pools.append([x0, x1, surface, pool])
		var bump := rng.randf_range(-1.0, 1.0) * amp
		var steps := maxi(2, int((x1 - x0) / 24.0))
		for s in range(1, steps):
			var u := float(s) / steps
			var h: float
			if pool != "":
				h = lerpf(lerpf(f[2], g[2], u), surface - 70.0, pow(sin(PI * u), 0.4))
			else:
				h = maxf(lerpf(f[2], g[2], smoothstep(0.0, 1.0, u)) + bump * sin(PI * u), -20.0)
			points.append(Vector2(lerpf(x0, x1, u), GROUND_Y - h))
	level.ground = points
