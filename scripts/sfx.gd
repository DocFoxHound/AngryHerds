extends Node
## Sound effects, synthesized at startup so the game ships without audio files.
## Sfx.play("wood") from anywhere.

const RATE := 22050
const VOICES := 12
## The same sound won't restart more often than this, so a pile-up doesn't turn into noise.
const MIN_GAP_MSEC := 45

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var last_played := {}


func _ready() -> void:
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	sounds["wood"] = _wav(_crack(0.22, 0.35, 170.0, 16.0))
	sounds["wood_break"] = _wav(_crack(0.45, 0.4, 150.0, 8.0))
	sounds["stone"] = _wav(_crack(0.25, 0.12, 70.0, 14.0))
	sounds["stone_break"] = _wav(_crack(0.5, 0.1, 60.0, 7.0))
	sounds["ice"] = _wav(_tinkle(0.25, 4))
	sounds["ice_break"] = _wav(_tinkle(0.5, 9))
	sounds["thud"] = _wav(_thud())
	sounds["poof"] = _wav(_poof())
	sounds["launch"] = _wav(_launch())
	sounds["ability"] = _wav(_sweep(0.16, 400.0, 1200.0))
	sounds["wolf"] = _wav(_sweep(0.22, 950.0, 420.0))
	sounds["star"] = _wav(_notes([1320.0], 0.5))
	sounds["win"] = _wav(_notes([523.0, 659.0, 784.0, 1047.0], 0.13))
	sounds["lose"] = _wav(_notes([392.0, 330.0, 262.0], 0.25))
	sounds["hay"] = _wav(_crack(0.2, 0.6, 300.0, 18.0))
	sounds["glass_break"] = _wav(_tinkle(0.6, 12))
	sounds["clang"] = _wav(_clang())
	sounds["growl"] = _wav(_growl(0.9, 82.0, 0.5))
	sounds["roar"] = _wav(_growl(1.4, 56.0, 0.9))
	sounds["howl"] = _wav(_howl())
	sounds["laugh"] = _wav(_laugh())
	sounds["baa"] = _wav(_voice(0.6, 340.0, 300.0, 22.0, 0.8, 0.25, 0.25, false))
	sounds["bleat"] = _wav(_voice(0.45, 540.0, 480.0, 30.0, 0.8, 0.3, 0.3, false))
	sounds["moo"] = _wav(_voice(1.0, 150.0, 112.0, 0.0, 0.0, 0.03, 0.16, false))
	sounds["quack"] = _wav(_voice(0.22, 430.0, 360.0, 0.0, 0.0, 0.5, 0.5, true))
	sounds["cluck"] = _wav(_cluck())
	sounds["oink"] = _wav(_oink())
	sounds["snort"] = _wav(_snort())
	sounds["boom"] = _wav(_boom())
	sounds["splash"] = _wav(_splash())
	sounds["sizzle"] = _wav(_sizzle())
	sounds["egg"] = _wav(_sweep(0.08, 900.0, 300.0))
	sounds["click"] = _wav(_click())
	sounds["step"] = _wav(_thud())
	sounds["reveal"] = _wav(_notes([523.0, 659.0, 784.0, 1047.0, 1319.0], 0.08))
	sounds["unlock"] = _wav(_notes([784.0, 988.0, 1175.0, 1568.0], 0.1))
	sounds["boss"] = _wav(_notes([147.0, 175.0, 208.0, 147.0], 0.2))


## min_gap_msec stops the same sound restarting too soon (raise it for ambient sounds).
func play(sound: String, volume_db := 0.0, pitch := 1.0, min_gap_msec := MIN_GAP_MSEC) -> void:
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(sound, -100000)) < min_gap_msec:
		return
	last_played[sound] = now
	for player in players:
		if not player.playing:
			player.stream = sounds[sound]
			player.volume_db = volume_db
			player.pitch_scale = pitch * randf_range(0.92, 1.08)
			player.play()
			return


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.001
	for s in samples:
		peak = maxf(peak, absf(s))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(samples[i] / peak * 0.8 * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	return wav


func _buffer(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(RATE * seconds))
	return out


## Filtered noise with crackles over a knock: wood (bright) or stone (dull) depending on the filter.
func _crack(seconds: float, brightness: float, knock_hz: float, decay: float) -> PackedFloat32Array:
	var out := _buffer(seconds)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * brightness
		var crackle := randf_range(-1.0, 1.0) if randf() < 0.03 else 0.0
		out[i] = (lp + crackle * 0.7) * exp(-t * decay) + sin(TAU * knock_hz * t) * exp(-t * 22.0) * 0.6
	return out


## High glassy partials: ice.
func _tinkle(seconds: float, partials: int) -> PackedFloat32Array:
	var out := _buffer(seconds)
	var freqs := []
	var starts := []
	for p in partials:
		freqs.append(randf_range(1800.0, 4800.0))
		starts.append(randf_range(0.0, seconds * 0.4))
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var noise := randf_range(-1.0, 1.0)
		lp += (noise - lp) * 0.3
		var s := (noise - lp) * exp(-t * 30.0) * 0.5
		for p in partials:
			var local: float = t - starts[p]
			if local > 0.0:
				s += sin(TAU * freqs[p] * local) * exp(-local * 18.0) * 0.4
		out[i] = s
	return out


func _thud() -> PackedFloat32Array:
	var out := _buffer(0.18)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * lerpf(110.0, 45.0, t / 0.18) / RATE
		out[i] = sin(phase) * exp(-t * 20.0) + randf_range(-0.2, 0.2) * exp(-t * 40.0)
	return out


func _poof() -> PackedFloat32Array:
	var out := _buffer(0.4)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * lerpf(0.35, 0.03, t / 0.4)
		out[i] = lp * minf(t / 0.015, 1.0) * exp(-t * 8.0)
	return out


## The band's twang plus a whoosh.
func _launch() -> PackedFloat32Array:
	var out := _buffer(0.35)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * 0.08
		var twang := sin(TAU * (160.0 - t * 120.0) * t) * exp(-t * 9.0)
		out[i] = twang + lp * 2.0 * sin(PI * t / 0.35)
	return out


func _sweep(seconds: float, from_hz: float, to_hz: float) -> PackedFloat32Array:
	var out := _buffer(seconds)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * lerpf(from_hz, to_hz, t / seconds) / RATE
		out[i] = (sin(phase) + 0.3 * sin(phase * 2.0)) * sin(PI * t / seconds)
	return out


func _notes(freqs: Array, note_seconds: float) -> PackedFloat32Array:
	var tail := 0.4
	var out := _buffer(note_seconds * freqs.size() + tail)
	for n in freqs.size():
		var start := int(n * note_seconds * RATE)
		for i in range(start, out.size()):
			var t := float(i - start) / RATE
			var f: float = freqs[n]
			out[i] += (sin(TAU * f * t) + 0.25 * sin(TAU * f * 2.0 * t)) * exp(-t * 6.0) * minf(t / 0.005, 1.0)
	return out


## A rattling, rumbling growl; low and long for a boss roar.
func _growl(seconds: float, base_hz: float, roughness: float) -> PackedFloat32Array:
	var out := _buffer(seconds)
	var phase := 0.0
	var lp := 0.0
	var noise_lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += base_hz * (1.0 + 0.08 * sin(TAU * 3.0 * t)) / RATE
		var saw := 2.0 * fposmod(phase, 1.0) - 1.0
		noise_lp += (randf_range(-1.0, 1.0) - noise_lp) * 0.1
		lp += (saw * 0.7 + noise_lp * roughness - lp) * 0.25
		var rattle := 0.55 + 0.45 * sin(TAU * (18.0 + 6.0 * sin(t * 7.0)) * t)
		var env := minf(t / 0.12, 1.0) * clampf((seconds - t) / 0.25, 0.0, 1.0)
		out[i] = lp * rattle * env
	return out


func _howl() -> PackedFloat32Array:
	var seconds := 1.6
	var out := _buffer(seconds)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var f := lerpf(330.0, 620.0, smoothstep(0.0, 0.35, t))
		if t > 1.2:
			f = lerpf(620.0, 420.0, (t - 1.2) / 0.4)
		f += sin(TAU * 5.0 * t) * 14.0 * smoothstep(0.3, 0.6, t)
		phase += TAU * f / RATE
		var env := minf(t / 0.15, 1.0) * clampf((seconds - t) / 0.3, 0.0, 1.0)
		out[i] = (sin(phase) + 0.3 * sin(phase * 2.0) + randf_range(-0.05, 0.05)) * env
	return out


## "Heh heh heh": wolves enjoying a miss.
func _laugh() -> PackedFloat32Array:
	var out := _buffer(0.8)
	var phase := 0.0
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var beat := fmod(t, 0.15)
		var n := int(t / 0.15)
		var on := beat < 0.09
		phase += (300.0 - n * 18.0 - beat * 300.0) / RATE
		var saw := 2.0 * fposmod(phase, 1.0) - 1.0
		lp += (saw * 0.8 + randf_range(-0.3, 0.3) - lp) * 0.3
		out[i] = lp * (sin(PI * beat / 0.09) if on else 0.0)
	return out


## A sawtooth "voice" with a wobble (tremolo) and a filter that can open over time: moo, baa.
func _voice(seconds: float, from_hz: float, to_hz: float, trem_hz: float, trem_depth: float,
		bright_from: float, bright_to: float, nasal: bool) -> PackedFloat32Array:
	var out := _buffer(seconds)
	var phase := 0.0
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var u := t / seconds
		phase += lerpf(from_hz, to_hz, u) * (1.0 + 0.02 * sin(TAU * 5.0 * t)) / RATE
		var saw := 2.0 * fposmod(phase, 1.0) - 1.0
		lp += (saw - lp) * lerpf(bright_from, bright_to, minf(u * 3.0, 1.0))
		var s := saw - lp * 0.7 if nasal else lp
		var trem := 1.0 - trem_depth * 0.5 * (1.0 + sin(TAU * trem_hz * t))
		var env := minf(t / 0.04, 1.0) * clampf((seconds - t) / 0.12, 0.0, 1.0)
		out[i] = s * trem * env
	return out


func _cluck() -> PackedFloat32Array:
	var out := _buffer(0.4)
	for i in out.size():
		var t := float(i) / RATE
		var beat := fmod(t, 0.12)
		if beat < 0.05:
			var f := lerpf(950.0, 600.0, beat / 0.05)
			out[i] = (signf(sin(TAU * f * beat)) * 0.5 + randf_range(-0.3, 0.3)) * sin(PI * beat / 0.05)
	return out


func _oink() -> PackedFloat32Array:
	var out := _buffer(0.4)
	var phase := 0.0
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var beat := fmod(t, 0.2)
		var on := beat < 0.13
		phase += (170.0 + 60.0 * sin(PI * beat / 0.13)) / RATE
		var saw := 2.0 * fposmod(phase, 1.0) - 1.0
		lp += (saw + randf_range(-0.6, 0.6) - lp) * 0.2
		out[i] = (saw - lp) * (sin(PI * beat / 0.13) if on else 0.0)
	return out


func _snort() -> PackedFloat32Array:
	var out := _buffer(0.35)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * 0.15
		out[i] = lp * (0.6 + 0.4 * sin(TAU * 40.0 * t)) * sin(PI * t / 0.35)
	return out


func _boom() -> PackedFloat32Array:
	var out := _buffer(1.0)
	var lp := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * 0.05
		phase += TAU * lerpf(60.0, 28.0, t) / RATE
		out[i] = (lp * 3.0 + sin(phase) * 0.8) * exp(-t * 3.5) * minf(t / 0.005, 1.0)
	return out


func _splash() -> PackedFloat32Array:
	var out := _buffer(0.55)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var noise := randf_range(-1.0, 1.0)
		lp += (noise - lp) * 0.5
		var bubble := sin(TAU * (700.0 + 500.0 * fmod(t * 9.0, 1.0)) * t) * 0.3 * exp(-fmod(t, 0.11) * 30.0)
		out[i] = lp * exp(-t * 7.0) + bubble * exp(-t * 4.0)
	return out


func _sizzle() -> PackedFloat32Array:
	var out := _buffer(0.7)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var noise := randf_range(-1.0, 1.0)
		lp += (noise - lp) * 0.3
		var crackle := randf_range(-1.0, 1.0) if randf() < 0.02 else 0.0
		out[i] = ((noise - lp) * 0.6 + crackle) * minf(t / 0.02, 1.0) * exp(-t * 4.0)
	return out


func _clang() -> PackedFloat32Array:
	var out := _buffer(0.7)
	var partials := [523.0, 1307.0, 2090.0, 2960.0, 3700.0]
	for i in out.size():
		var t := float(i) / RATE
		var s := 0.0
		for k in partials.size():
			s += sin(TAU * partials[k] * t) * exp(-t * (4.0 + k * 2.5)) / (k + 1.0)
		out[i] = s * minf(t / 0.002, 1.0)
	return out


func _click() -> PackedFloat32Array:
	var out := _buffer(0.04)
	for i in out.size():
		var t := float(i) / RATE
		out[i] = signf(sin(TAU * 1800.0 * t)) * exp(-t * 120.0)
	return out
