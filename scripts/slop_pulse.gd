extends Node
## Slop Pulse: lets the Slop store show player counts. Sends only the session token,
## and does nothing unless the game was started from the Slop desktop app.

var token := OS.get_environment("SLOP_PULSE_TOKEN")
var url := OS.get_environment("SLOP_PULSE_URL")


func _ready() -> void:
	if token.is_empty() or url.is_empty():
		return
	var every := OS.get_environment("SLOP_PULSE_INTERVAL")
	var timer := Timer.new()
	timer.wait_time = float(every) if every.is_valid_int() else 60.0
	timer.timeout.connect(func(): _post("heartbeat"))
	add_child(timer)
	_post("start")
	timer.start()


func _post(path: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _code, _h, _b): http.queue_free())
	http.request(url + "/" + path, ["Content-Type: application/json"], HTTPClient.METHOD_POST,
		JSON.stringify({"token": token}))
