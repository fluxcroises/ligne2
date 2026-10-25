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
var _outbox: Array[Dictionary] = []      # messages en attente de réseau


func _ready() -> void:
	for m in Chapitre1.PROLOGUE:
		send_to_player(m.from, m.text, m.get("evidence", ""))


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
