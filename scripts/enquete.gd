extends Node
## État de l'enquête, partagé par tout le jeu : dossier, photos, messages, déductions,
## batterie et réseau. Le téléphone ne fait que l'afficher.

signal evidence_added(item: Dictionary)
signal message_received(message: Dictionary)
signal deduction_solved(id: String)

const PHOTO_COST := 2.0
const SEARCH_COST := 1.0

var chapter := 1
var battery := 100.0
## Tenu à jour par le lieu : pas de 4G sous terre.
var underground := false
var unlocked_stations: Array[String] = ["Monceau"]

var evidence: Array[Dictionary] = []     # {id, kind, title, text, chapter, texture}
var photos: Array[Dictionary] = []       # {texture, time, evidence}
var messages: Array[Dictionary] = []     # {from, text, time, read, evidence}
var solved: Array[String] = []
## Ce que le joueur a appris ou provoqué (« sylvain_pause », « jo_parle »…).
var flags := {}
## Vrai pendant un dialogue : le téléphone reste rangé.
var in_dialogue := false
## Messages d'aide de Nadia quand on tourne en rond.
var hints_enabled := true
var hints_sent: Array[String] = []
var _outbox: Array[Dictionary] = []      # messages en attente de réseau

## Vrai une fois une partie commencée ou chargée.
var started := false
## Position du détective et heure de jeu à rétablir au chargement (appliquées par le chapitre).
var pending_load := {}

const SAVE_PATH := "user://sauvegarde.json"
const PHOTO_DIR := "user://photos"


func _ready() -> void:
	evidence_added.connect(func(_e: Dictionary) -> void: _autosave.call_deferred())
	deduction_solved.connect(func(_d: String) -> void: _autosave.call_deferred())


func reset() -> void:
	chapter = 1
	battery = 100.0
	underground = false
	unlocked_stations = ["Monceau"]
	evidence.clear()
	photos.clear()
	messages.clear()
	solved.clear()
	flags.clear()
	hints_sent.clear()
	_outbox.clear()
	in_dialogue = false
	pending_load = {}


## Nouvelle partie : prologue du chapitre 1 (les messages de Nadia).
func new_game() -> void:
	reset()
	started = true
	_loading = true
	for m in Chapitre1.PROLOGUE:
		send_to_player(m.from, m.text, m.get("evidence", ""))
	_loading = false


# --- Sauvegarde ----------------------------------------------------------------
# Automatique à chaque nouvelle pièce du dossier et à chaque déduction (et en quittant).

var _loading := false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _autosave() -> void:
	if started and not _loading and get_tree().current_scene and get_tree().current_scene.has_node("Monceau"):
		save_game()


func save_game() -> void:
	DirAccess.make_dir_recursive_absolute(PHOTO_DIR)
	var items := []
	for e in evidence:
		var image := ""
		var tex: Texture2D = e.texture
		if tex and tex.resource_path != "":
			image = tex.resource_path
		elif tex:
			image = "%s/%s.png" % [PHOTO_DIR, e.id]
			tex.get_image().save_png(image)
		items.append({"id": e.id, "image": image})
	var data := {
		"version": 1, "chapter": chapter, "battery": battery, "unlocked": unlocked_stations,
		"flags": flags, "solved": solved, "hints_sent": hints_sent, "evidence": items,
		"messages": messages, "outbox": _outbox,
	}
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var p := player.global_position
		data.player = [p.x, p.y, p.z, player.rotation.y]
	var trafic := _trafic()
	if trafic:
		data.time = trafic.time
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))


## Charge la sauvegarde ; la position et l'heure sont appliquées une fois Monceau chargée.
func load_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not data is Dictionary:
		return false
	reset()
	_loading = true
	chapter = int(data.get("chapter", 1))
	battery = float(data.get("battery", 100.0))
	unlocked_stations.assign(data.get("unlocked", ["Monceau"]))
	flags = data.get("flags", {})
	solved.assign(data.get("solved", []))
	hints_sent.assign(data.get("hints_sent", []))
	for item in data.get("evidence", []):
		var tex: Texture2D = null
		var path: String = item.get("image", "")
		if path.begins_with("res://"):
			tex = load(path)
		elif path != "" and FileAccess.file_exists(path):
			tex = ImageTexture.create_from_image(Image.load_from_file(path))
		add_evidence(item.id, tex)
	for m in data.get("messages", []):
		messages.append(m)
	for m in data.get("outbox", []):
		_outbox.append(m)
	pending_load = {"player": data.get("player", []), "time": data.get("time", 0.0)}
	_loading = false
	started = true
	return true


func _process(_delta: float) -> void:
	if not _outbox.is_empty() and has_network():
		_deliver()


func has_network() -> bool:
	return not underground


func clock_text() -> String:
	var trafic := _trafic()
	return trafic.clock_text() if trafic else "23:05"


## Heure de jeu en minutes depuis minuit.
func minutes() -> int:
	var trafic := _trafic()
	return trafic.minutes() if trafic else Chapitre1.START


func _trafic() -> Node:
	var scene := get_tree().current_scene
	return scene.get_node_or_null("Monceau/Trafic") if scene else null


## Dépense de la batterie ; renvoie false si elle est vide.
func use_battery(amount: float) -> bool:
	if battery <= 0.0:
		return false
	battery = maxf(0.0, battery - amount)
	return true


# --- Dossier -------------------------------------------------------------------

func has_evidence(id: String) -> bool:
	return evidence.any(func(e): return e.id == id)


## Ajoute une pièce définie dans le chapitre ; renvoie false si elle y est déjà.
func add_evidence(id: String, texture: Texture2D = null) -> bool:
	if has_evidence(id) or not Chapitre1.EVIDENCE.has(id):
		return false
	var def: Dictionary = Chapitre1.EVIDENCE[id]
	var item := {"id": id, "kind": def.kind, "title": def.title, "text": def.text,
		"chapter": chapter, "texture": texture}
	evidence.append(item)
	evidence_added.emit(item)
	return true


## L'image fournie avec une pièce (photo envoyée, trouvée en ligne) : textures/photo_<pièce>.png.
static func evidence_image(id: String) -> Texture2D:
	return load("res://textures/%s.png" % (id if id.begins_with("photo_") else "photo_" + id))


func add_photo(texture: Texture2D, evidence_id := "") -> void:
	photos.append({"texture": texture, "time": clock_text(), "evidence": evidence_id})


# --- Messages ------------------------------------------------------------------

## Un message pour le joueur ; il n'arrive que lorsque le téléphone capte.
func send_to_player(from: String, text: String, evidence_id := "") -> void:
	_outbox.append({"from": from, "text": text, "evidence": evidence_id})
	if has_network():
		_deliver()


func _deliver() -> void:
	for m in _outbox:
		m.time = clock_text()
		m.read = false
		messages.append(m)
		if m.evidence != "":
			add_evidence(m.evidence, evidence_image(m.evidence))
		message_received.emit(m)
	_outbox.clear()


func unread_count(from := "") -> int:
	return messages.filter(func(m): return not m.read and (from == "" or m.from == from)).size()


func contacts() -> Array[String]:
	var names: Array[String] = []
	for m in messages:
		if not names.has(m.from):
			names.append(m.from)
	return names


# --- Conditions et effets (dialogues) ------------------------------------------

## Condition d'un choix ou d'une réaction : « drapeau », « !drapeau », « has:pièce »,
## « solved:déduction ». Plusieurs conditions séparées par des espaces doivent toutes être vraies.
func check(condition: String) -> bool:
	for c in condition.split(" ", false):
		var negate := c.begins_with("!")
		var term := c.substr(1) if negate else c
		var value: bool
		if term.begins_with("has:"):
			value = has_evidence(term.substr(4))
		elif term.begins_with("solved:"):
			value = solved.has(term.substr(7))
		else:
			value = flags.get(term, false)
		if value == negate:
			return false
	return true


## Effets d'un nœud de dialogue : « set » (drapeaux), « evidence » (pièce du dossier).
func apply(node: Dictionary) -> Array[String]:
	var added: Array[String] = []
	for f in node.get("set", []):
		flags[f] = true
	var id: String = node.get("evidence", "")
	if id != "" and add_evidence(id):
		added.append(Chapitre1.EVIDENCE[id].title)
	return added


# --- Déductions ----------------------------------------------------------------

## Vérifie une déduction : les éléments reliés et la conclusion choisie.
## Renvoie {ok, text}.
func try_deduction(id: String, elements: Array, conclusion: int) -> Dictionary:
	for d in Chapitre1.DEDUCTIONS:
		if d.id != id:
			continue
		var expected: Array = d.elements.duplicate()
		var given := elements.duplicate()
		expected.sort()
		given.sort()
		if given != expected:
			return {"ok": false, "text": "Ces éléments ne suffisent pas, ou ne vont pas ensemble."}
		if conclusion != d.answer:
			return {"ok": false, "text": "Ça ne colle pas avec les preuves."}
		if not solved.has(id):
			solved.append(id)
			deduction_solved.emit(id)
		return {"ok": true, "text": d.success}
	return {"ok": false, "text": ""}
