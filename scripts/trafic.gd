class_name Trafic
extends Node3D
## Le trafic de la ligne 2 à Monceau, repris du prototype : une rame par voie, un passage
## toutes les 94 secondes ; écrans des prochains passages ; grondement des rames et bip de
## fermeture des portes. Le joueur peut monter à bord : la rame repart puis revient à quai
## (en attendant les autres stations).

const CYCLE := 94.0
const APPROACH := 110.0     # distance d'où la rame arrive, et où elle disparaît

## Heure de jeu au lancement, en minutes : le chapitre 1 commence vers 23 h 05.
var clock_start := 23 * 60 + 5
var time := 0.0
var trains: Array[MF01] = []
var siel_materials: Array[ShaderMaterial] = []

var _barriers: Array[CollisionShape3D] = []
var _siel: Array[Dictionary] = []
var _last_second := -1
var _rumble: AudioStreamPlayer
var _beep: AudioStreamPlayer
var _gain := 0.0


## `rails_y` : niveau des rails ; `tracks` : [z de la voie, côté des portes, sens, décalage,
## destination] ; `barriers` : garde-fous des quais, ôtés quand une rame est à quai.
func setup(M: Dictionary, rails_y: float, floor_height: float, tracks: Array, barriers: Array[CollisionShape3D]) -> void:
	_barriers = barriers
	for t in tracks:
		var train := MF01.new(M, floor_height, t[1], t[2], t[3], t[4])
		train.position = Vector3(300, rails_y, t[0])
		add_child(train)
		trains.append(train)
		var siel := _make_siel(t[4])
		_siel.append(siel)
		var m: ShaderMaterial = M.inox.duplicate()
		m.set_shader_parameter("albedo_texture", siel.viewport.get_texture())
		m.set_shader_parameter("albedo_color", Vector3.ONE)
		siel_materials.append(m)
	_rumble = AudioStreamPlayer.new()
	_rumble.stream = _rumble_stream()
	_rumble.volume_db = -80.0
	add_child(_rumble)
	_rumble.play()
	_beep = AudioStreamPlayer.new()
	_beep.stream = _beep_stream()
	_beep.volume_db = -6.0
	add_child(_beep)


## Position de la rame dans son cycle : arrivée (9 s), arrêt (18 s), départ (9 s), absence.
func state(train: MF01) -> Dictionary:
	var k := fposmod(time + train.offset, CYCLE)
	var d := float(train.direction)
	if k < 9.0:
		var s := k / 9.0
		return {"k": k, "x": d * APPROACH * (1 - s) * (1 - s), "v": d * 2 * APPROACH * (1 - s) / 9.0}
	if k < 27.0:
		return {"k": k, "x": 0.0, "v": 0.0}
	if k < 36.0:
		var s := (k - 27.0) / 9.0
		return {"k": k, "x": -d * APPROACH * s * s, "v": -d * 2 * APPROACH * s / 9.0}
	return {"k": k, "x": 300.0, "v": 0.0, "hidden": true}


## La rame où se trouve le joueur, ou null.
func train_at(pos: Vector3) -> MF01:
	for train in trains:
		if train.contains(pos):
			return train
	return null


func is_moving(train: MF01) -> bool:
	return state(train).v != 0.0


## Heure de jeu « hh:mm ».
func clock_text() -> String:
	var minutes := (clock_start + int(time / 60.0)) % (24 * 60)
	return "%02d:%02d" % [minutes / 60, minutes % 60]


func _physics_process(delta: float) -> void:
	time += delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var rumble := 0.0
	for i in trains.size():
		var train := trains[i]
		var aboard := player != null and train.contains(player.global_position)
		var st := state(train)
		if aboard and st.k >= 36.0:
			# à bord : on enchaîne directement sur l'arrivée suivante
			train.offset += CYCLE - st.k
			st = state(train)
		var dx: float = st.x - train.position.x
		train.position.x = st.x
		if aboard:
			player.global_position.x += dx
		train.visible = not st.has("hidden")

		var open: bool = st.k > 10.0 and st.k < 24.0
		train.set_doors(train.doors_amount + ((1.0 if open else 0.0) - train.doors_amount) * minf(1.0, delta * 3.0))
		if st.k > 23.0 and st.k < 24.0 and not train.beeped:
			train.beeped = true
			if player and player.global_position.y < -5.0 and absf(train.position.z - player.global_position.z) < 14.0:
				_beep.play()
		if st.k < 1.0:
			train.beeped = false

		# garde-fou du quai : ôté tant que la rame est à quai
		var at_platform: bool = st.k >= 9.0 and st.k < 27.0
		if i < _barriers.size() and _barriers[i].disabled != at_platform:
			_barriers[i].set_deferred("disabled", at_platform)

		if player and train.visible:
			var dist := Vector2(st.x - player.global_position.x, train.position.z - player.global_position.z).length()
			rumble += (minf(1.0, absf(st.v) / 18.0) * 0.9 + 0.08) / (1.0 + dist / 18.0)
	if player and player.global_position.y > -5.0:
		rumble *= 0.15
	_gain += (minf(0.9, rumble) - _gain) * minf(1.0, delta * 4.0)
	_rumble.volume_db = linear_to_db(maxf(_gain, 0.0001))

	if int(time) != _last_second:
		_last_second = int(time)
		for i in trains.size():
			_update_siel(_siel[i], trains[i])


# --- Écran des prochains passages (SIEL) --------------------------------------

func _make_siel(destination: String) -> Dictionary:
	var vp := SubViewport.new()
	vp.size = Vector2i(128, 48)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_rect(vp, Color("#ecebe5"), Rect2(0, 0, 128, 14))
	_disc(vp, Color("#ecebe5"), Color("#14286e"), Vector2(8, 7), "M")
	_disc(vp, Color("#1d5fd0"), Color.TRANSPARENT, Vector2(20, 7), "2")
	_text(vp, "Pte Dauphine" if destination == "Porte Dauphine" else destination, Color("#14286e"), 10, Vector2(29, 1))
	_rect(vp, Color("#101114"), Rect2(0, 14, 72, 30))
	_text(vp, "1er métro", Color("#f0f0f0"), 6, Vector2(4, 15))
	_text(vp, "2e métro", Color("#f0f0f0"), 6, Vector2(38, 15))
	_rect(vp, Color("#dddddd"), Rect2(35, 24, 1, 17))
	var first := _text(vp, "1", Color("#f2b51e"), 18, Vector2(12, 22))
	var second := _text(vp, "2", Color("#f2b51e"), 18, Vector2(44, 22))
	_rect(vp, Color("#f4f4f2"), Rect2(72, 14, 56, 30))
	_text(vp, "Attentifs,\nensemble", Color("#14286e"), 6, Vector2(75, 19))
	_rect(vp, Color("#3a3418"), Rect2(100, 15, 27, 9))
	var clock := _text(vp, "23:05", Color("#f2c94c"), 7, Vector2(102, 15))
	_rect(vp, Color("#3d8a4a"), Rect2(0, 44, 128, 4))
	return {"viewport": vp, "first": first, "second": second, "clock": clock}


func _update_siel(siel: Dictionary, train: MF01) -> void:
	var k := fposmod(time + train.offset, CYCLE)
	var wait := 9.0 - k if k < 9.0 else (0.0 if k < 27.0 else CYCLE - k + 9.0)
	siel.first.text = str(ceili(wait / 60.0))
	siel.second.text = str(ceili((wait + CYCLE) / 60.0))
	siel.clock.text = clock_text()


func _rect(parent: Node, color: Color, r: Rect2) -> void:
	var c := ColorRect.new()
	c.color = color
	c.position = r.position
	c.size = r.size
	parent.add_child(c)


func _disc(parent: Node, fill: Color, ring: Color, center: Vector2, letter: String) -> void:
	var p := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(5)
	if ring.a > 0.0:
		style.border_color = ring
		style.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", style)
	p.position = center - Vector2(5, 5)
	p.size = Vector2(10, 10)
	parent.add_child(p)
	var l := _text(parent, letter, ring if ring.a > 0.0 else Color.WHITE, 8, center - Vector2(5, 6))
	l.size = Vector2(10, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _text(parent: Node, s: String, color: Color, font_size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = s
	l.position = pos
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_constant_override("line_spacing", -3)
	parent.add_child(l)
	return l


# --- Sons fabriqués au lancement ----------------------------------------------

const RATE := 22050


## Grondement : bruit brun filtré passe-bas (260 Hz), en boucle.
func _rumble_stream() -> AudioStreamWAV:
	var n := RATE * 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var samples := PackedFloat32Array()
	samples.resize(n)
	var v := 0.0
	var lp := 0.0
	var a := 1.0 - exp(-TAU * 260.0 / RATE)
	for i in n:
		v = (v + 0.02 * rng.randf_range(-1.0, 1.0)) / 1.02
		lp += a * (v * 3.5 - lp)
		samples[i] = lp
	# fondu enchaîné entre la fin et le début, pour une boucle sans clic
	var fade := RATE / 10
	for i in fade:
		var t := float(i) / fade
		samples[i] = samples[i] * t + samples[n - fade + i] * (1.0 - t)
	return _wav(samples.slice(0, n - fade), true)


## Bip de fermeture des portes : deux bips carrés à 880 Hz.
func _beep_stream() -> AudioStreamWAV:
	var n := int(RATE * 0.7)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var local := fmod(t, 0.35)
		if local < 0.25:
			var env := minf(1.0, local / 0.02) * exp(-local * 12.0)
			samples[i] = (1.0 if fmod(t * 880.0, 1.0) < 0.5 else -1.0) * 0.3 * env
	return _wav(samples, false)


func _wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = samples.size()
	return w
