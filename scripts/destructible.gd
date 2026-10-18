extends RigidBody2D
## Base for anything that breaks when hit hard enough (blocks, wolves).

signal destroyed(node: Node)

var max_health := 100.0
var health := 100.0
## Contact impulses below this are ignored (resting weight, light bumps).
var damage_threshold := 100.0
## Seconds after spawning during which damage is ignored, so the level can settle.
var grace := 1.5


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	health = max_health


func _physics_process(delta: float) -> void:
	grace -= delta


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if grace > 0.0 or health <= 0.0:
		return
	for i in state.get_contact_count():
		var impulse = state.get_contact_impulse(i)
		var magnitude: float = impulse.length() if impulse is Vector2 else float(impulse)
		if magnitude > damage_threshold:
			take_damage(magnitude - damage_threshold)


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	queue_redraw()
	if health <= 0.0:
		destroyed.emit(self)
		queue_free.call_deferred()


func damage_ratio() -> float:
	return clampf(1.0 - health / max_health, 0.0, 1.0)
