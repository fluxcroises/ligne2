class_name Chapitres
## Registre des chapitres : le contenu de chacun (Chapitre1, Chapitre2… : pièces du dossier,
## messages, dialogues, déductions, recherches, aides) et la scène de son lieu.
## Le dossier, les déductions et les recherches s'accumulent d'un chapitre à l'autre.

const LAST := 4


static func content(n: int) -> GDScript:
	match n:
		2: return Chapitre2
		3: return Chapitre3
		4: return Chapitre4
	return Chapitre1


static func all(upto := LAST) -> Array[GDScript]:
	var out: Array[GDScript] = []
	for n in range(1, mini(upto, LAST) + 1):
		out.append(content(n))
	return out


static func scene(n: int) -> String:
	match n:
		2: return "res://scenes/villiers.tscn"
		3: return "res://scenes/pigalle.tscn"
		4: return "res://scenes/jaures.tscn"
	return "res://scenes/main.tscn"


static func station(n: int) -> String:
	return content(n).STATION


static func start(n: int) -> int:
	return content(n).START


## Définition d'une pièce du dossier, quel que soit son chapitre ({} si inconnue).
static func evidence(id: String) -> Dictionary:
	for c in all():
		if c.EVIDENCE.has(id):
			return c.EVIDENCE[id]
	return {}


static func dialogue(id: String) -> Dictionary:
	for c in all():
		if c.DIALOGUES.has(id):
			return c.DIALOGUES[id]
	return {}


static func deductions(upto: int) -> Array:
	var out := []
	for c in all(upto):
		out.append_array(c.DEDUCTIONS)
	return out


static func searches(upto: int) -> Array:
	var out := []
	for c in all(upto):
		out.append_array(c.SEARCHES)
	return out
