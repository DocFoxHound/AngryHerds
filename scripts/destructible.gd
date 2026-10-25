extends RigidBody2D
## Base for anything that breaks when hit hard enough (blocks, wolves).

signal destroyed(node: Node)

const Effects := preload("res://scripts/effects.gd")

var max_health := 100.0
var health := 100.0
## Contact impulses below this are ignored (resting weight, light bumps).
var damage_threshold := 100.0
## Share of an impact (above the threshold) that turns into damage.
var impact_damage := 1.0
## The most one physics step of impacts can take off, as a share of max_health. Below 1, a
## single knock sends things tumbling instead of breaking them on the spot.
var max_hit := INF
## Seconds after spawning during which damage is ignored, so the level can settle.
var grace := 1.5
## Score for destroying it.
var points := 0
var hit_sound := "thud"


func _ready() -> void:
	add_to_group("destructible")
	contact_monitor = true
	max_contacts_reported = 8
	health = max_health
	# Start asleep, so a freshly built stack can't jitter itself apart before anything hits it.
	sleeping = true


func _physics_process(delta: float) -> void:
	grace -= delta


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if grace > 0.0 or health <= 0.0:
		return
	var damage := 0.0
	for i in state.get_contact_count():
		var impulse = state.get_contact_impulse(i)
		var magnitude: float = impulse.length() if impulse is Vector2 else float(impulse)
		if magnitude > damage_threshold:
			damage += (magnitude - damage_threshold) * impact_damage
	if damage > 0.0:
		take_damage(minf(damage, max_hit * max_health))


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	queue_redraw()
	if health <= 0.0:
		# Deferred: this runs mid physics step, where adding effect nodes isn't safe.
		_die.call_deferred()
	else:
		Sfx.play(hit_sound, linear_to_db(clampf(amount / max_health, 0.25, 1.0)))


func _die() -> void:
	_break()
	destroyed.emit(self)
	queue_free()


## Lost in water or lava: counts as destroyed, with a splash instead of the usual break.
func sink(lava: bool) -> void:
	if health <= 0.0:
		return
	health = 0.0
	Effects.splash(get_parent(), global_position, lava)
	destroyed.emit(self)
	queue_free()


## Override to spawn the breaking effect.
func _break() -> void:
	pass


func damage_ratio() -> float:
	return clampf(1.0 - health / max_health, 0.0, 1.0)
