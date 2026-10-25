extends Node
## Sons du jeu, tous fabriqués au lancement (aucun fichier audio) :
## ambiances de la rue et de la station en fondu selon que l'on est sous terre ou non,
## bruits de pas, déclic de l'appareil photo, vibration d'un message reçu.
## Le grondement des rames et le bip des portes sont dans Trafic.

const RATE := 22050

var playing := false             # vrai pendant une partie (pas sur l'écran titre)
var _rue: AudioStreamPlayer
var _station: AudioStreamPlayer
var _pas_rue: Array[AudioStreamWAV] = []
var _pas_station: Array[AudioStreamWAV] = []
var _effets: AudioStreamPlayer
var _pas: AudioStreamPlayer
var _streams := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 7
	_rue = _player(_loop(_street_noise(8.0)))
	_station = _player(_loop(_station_hum(6.0)))
	_effets = _player(null)
	_pas = _player(null)
	for i in 4:
		_pas_rue.append(_wav(_footstep(2200.0, 0.10)))
		_pas_station.append(_wav(_footstep(1300.0, 0.14)))
	_streams.declic = _wav(_shutter())
	_streams.vibreur = _wav(_buzz())


func _process(delta: float) -> void:
	var under := Enquete.underground
	var target_rue := 0.0 if not playing or under else 0.35
	var target_station := 0.0 if not playing or not under else 0.45
	_fade(_rue, target_rue, delta)
	_fade(_station, target_station, delta)


## Un pas : quatre variantes, plus sourdes sous terre (carrelage, écho) qu'en surface.
func pas() -> void:
	var bank := _pas_station if Enquete.underground else _pas_rue
	_pas.stream = bank[_rng.randi() % bank.size()]
	_pas.pitch_scale = _rng.randf_range(0.9, 1.1)
	_pas.volume_db = -14.0
	_pas.play()


func play(name: String, volume_db := -8.0) -> void:
	_effets.stream = _streams[name]
	_effets.volume_db = volume_db
	_effets.play()


func _fade(p: AudioStreamPlayer, target: float, delta: float) -> void:
	var current := db_to_linear(p.volume_db) if p.playing else 0.0
	current = move_toward(current, target, delta * 0.5)
	if current <= 0.001:
		if p.playing:
			p.stop()
		return
	p.volume_db = linear_to_db(current)
	if not p.playing:
		p.play()


func _player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -80.0
	add_child(p)
	return p


# --- Fabrication des sons --------------------------------------------------------

## Rue la nuit : rumeur lointaine (bruit brun filtré) avec des voitures qui passent au loin.
func _street_noise(seconds: float) -> PackedFloat32Array:
	var n := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var brown := 0.0
	var lp := 0.0
	var a := 1.0 - exp(-TAU * 500.0 / RATE)
	for i in n:
		var t := float(i) / RATE
		brown = (brown + 0.02 * _rng.randf_range(-1, 1)) / 1.02
		lp += a * (brown * 3.0 - lp)
		var cars := 0.35 + 0.65 * pow(maxf(0.0, sin(t * TAU / seconds * 2.0 + 0.6)), 6.0)
		out[i] = lp * cars
	return out


## Station : souffle de ventilation et ronflement électrique à 50 Hz, très bas.
func _station_hum(seconds: float) -> PackedFloat32Array:
	var n := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var a := 1.0 - exp(-TAU * 900.0 / RATE)
	for i in n:
		var t := float(i) / RATE
		lp += a * (_rng.randf_range(-1, 1) * 0.25 - lp)
		var hum := 0.05 * sin(TAU * 50.0 * t) + 0.025 * sin(TAU * 100.0 * t)
		out[i] = lp + hum
	return out


## Pas : bref claquement de bruit filtré, qui s'éteint vite.
func _footstep(cutoff: float, length: float) -> PackedFloat32Array:
	var n := int(RATE * length)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var a := 1.0 - exp(-TAU * cutoff / RATE)
	for i in n:
		var t := float(i) / RATE
		lp += a * (_rng.randf_range(-1, 1) - lp)
		out[i] = lp * exp(-t * 45.0) * 0.9
	return out


## Déclic d'appareil photo : deux claquements secs.
func _shutter() -> PackedFloat32Array:
	var n := int(RATE * 0.16)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 90.0) + exp(-maxf(0.0, t - 0.07) * 90.0) * (1.0 if t > 0.07 else 0.0)
		out[i] = _rng.randf_range(-1, 1) * env * 0.6
	return out


## Vibreur : deux bourdonnements graves.
func _buzz() -> PackedFloat32Array:
	var n := int(RATE * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var on := 1.0 if fmod(t, 0.25) < 0.17 else 0.0
		out[i] = sin(TAU * 150.0 * t) * (0.6 + 0.4 * sin(TAU * 30.0 * t)) * on * 0.35
	return out


## Boucle sans clic : fondu enchaîné entre la fin et le début.
func _loop(samples: PackedFloat32Array) -> AudioStreamWAV:
	var n := samples.size()
	var fade := RATE / 5
	for i in fade:
		var k := float(i) / fade
		samples[i] = samples[i] * k + samples[n - fade + i] * (1.0 - k)
	var w := _wav(samples.slice(0, n - fade))
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n - fade
	return w


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w
