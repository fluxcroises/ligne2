class_name Chapitre1
## Contenu du chapitre 1 (Monceau) : pièces du dossier, messages, déductions.
## Le déroulé complet (personnages, horaires) viendra à l'étape 6.

const STATION := "Monceau"

## Pièces du dossier. `kind` : photo, indice ou temoignage.
const EVIDENCE := {
	"karim": {"kind": "photo", "title": "Photo de Karim",
		"text": "Karim Benali, 47 ans, conducteur sur la ligne 2 depuis vingt ans. Envoyée par Nadia."},
	"badge": {"kind": "photo", "title": "Badge RATP de Karim",
		"text": "Trouvé sous un siège orange, au bout du quai direction Porte Dauphine."},
	"serrure": {"kind": "photo", "title": "Serrure rayée",
		"text": "Porte de service au bout du quai : des rayures fraîches autour de la serrure."},
	"photo_voyageur": {"kind": "photo", "title": "Photo d'un voyageur",
		"text": "Publiée en ligne le soir de l'incident : un homme en gilet orange au bout du quai, 23 h 11."},
	"cahier": {"kind": "indice", "title": "Cahier de l'agent",
		"text": "Page du soir : « intervention maintenance » notée à 23 h 08, absente du planning officiel."},
	"temoignage_jo": {"kind": "temoignage", "title": "Témoignage de Jo",
		"text": "Karim est remonté vivant, accompagné d'un homme en gilet orange, sans résister."},
}

## Messages reçus au début du chapitre (prologue).
const PROLOGUE := [
	{"from": "Nadia", "text": "C'est Nadia Benali. Merci d'avoir accepté."},
	{"from": "Nadia", "text": "Voici la seule photo récente de Karim.", "evidence": "karim"},
	{"from": "Nadia", "text": "Sa rame est restée à quai à Monceau mardi soir, celle de 23 h 12. Portes ouvertes, cabine vide. Personne ne veut me dire ce qui s'est passé."},
]

const DEDUCTIONS := [
	{
		"id": "faux_agent",
		"question": "Que s'est-il passé à Monceau à 23 h 12 ?",
		"elements": ["badge", "serrure", "photo_voyageur", "cahier"],
		"conclusions": [
			"Karim a fait un malaise, puis il est parti de lui-même.",
			"Karim a fugué : il a quitté la rame et la station seul.",
			"Un faux agent a fait sortir Karim par la porte de service, et l'agent de station l'a couvert.",
		],
		"answer": 2,
		"success": "Le badge, la serrure, le gilet orange et la fausse intervention se recoupent : Karim n'est pas parti seul. Reste à le faire avouer à Sylvain.",
	},
]
