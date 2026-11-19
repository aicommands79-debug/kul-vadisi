extends Node
## Ses efektleri çalışma anında sentezlenir; projede tek bir ses dosyası yok.

const RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _streams := {}


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.volume_db = -9.0
		add_child(p)
		_players.append(p)

	_streams["swing"] = _sweep(640.0, 180.0, 0.10, "noise", 0.45)
	_streams["hit"] = _sweep(340.0, 120.0, 0.09, "square", 0.5)
	_streams["hurt"] = _sweep(300.0, 90.0, 0.22, "saw", 0.45)
	_streams["death"] = _sweep(280.0, 55.0, 0.45, "square", 0.45)
	_streams["coin"] = _arpeggio([988.0, 1319.0], 0.09, 0.4)
	_streams["pickup"] = _arpeggio([784.0, 1046.0], 0.07, 0.38)
	_streams["heal"] = _arpeggio([523.0, 659.0, 784.0], 0.08, 0.4)
	_streams["talk"] = _sweep(620.0, 720.0, 0.035, "sine", 0.25)
	_streams["chest"] = _arpeggio([392.0, 523.0, 659.0], 0.10, 0.4)
	_streams["portal"] = _arpeggio([392.0, 523.0, 659.0, 880.0], 0.08, 0.34)
	_streams["shrine"] = _arpeggio([523.0, 659.0, 784.0, 1046.0], 0.09, 0.35)
	_streams["rock"] = _sweep(150.0, 55.0, 0.18, "noise", 0.5)
	_streams["feather"] = _sweep(880.0, 540.0, 0.12, "sine", 0.3)
	_streams["boss"] = _sweep(92.0, 38.0, 1.1, "saw", 0.55)
	_streams["roar"] = _sweep(160.0, 48.0, 0.55, "square", 0.5)


func play(id: String, pitch: float = 1.0) -> void:
	if not _streams.has(id) or _players.is_empty():
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[id]
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()


func _sweep(f0: float, f1: float, dur: float, kind: String, vol: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f0 * 13.0 + dur * 997.0)
	for i in n:
		var t := float(i) / float(maxi(1, n - 1))
		var f := lerpf(f0, f1, t)
		phase += TAU * f / float(RATE)
		var env := pow(1.0 - t, 1.6)
		var v := 0.0
		match kind:
			"square":
				v = 1.0 if sin(phase) >= 0.0 else -1.0
			"saw":
				v = fposmod(phase / TAU, 1.0) * 2.0 - 1.0
			"noise":
				v = rng.randf_range(-1.0, 1.0) * 0.65 + sin(phase) * 0.45
			_:
				v = sin(phase)
		s[i] = v * env * vol
	return _to_wav(s)


func _arpeggio(freqs: Array, note_dur: float, vol: float) -> AudioStreamWAV:
	var total := float(freqs.size()) * note_dur
	var n := int(RATE * total)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(RATE)
		var idx := mini(freqs.size() - 1, int(t / note_dur))
		var f: float = freqs[idx]
		var local := fmod(t, note_dur) / note_dur
		var env := pow(1.0 - local, 2.0)
		phase += TAU * f / float(RATE)
		s[i] = sin(phase) * env * vol
	return _to_wav(s)


func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
