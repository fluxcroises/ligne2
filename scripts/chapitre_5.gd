class_name Chapitre5
## Contenu du chapitre 5 (Nation) : Karim. Bruno, conducteur de manœuvre, entend frapper dans le
## local 14 de la boucle de retournement ; quand on lui montre ce qu'a vu Josiane, il ouvre la
## porte de service. Dans la boucle, Franck garde la grille. La déduction faite, et Marchetti
## ayant parlé, Franck cède et donne la clé. Karim est vivant.

const STATION := "Nation"

const EVIDENCE := {
	"temoignage_bruno": {"kind": "temoignage", "title": "Témoignage de Bruno",
		"text": "Depuis mardi, le local 14 de la boucle de retournement est fermé par un cadenas neuf. Delorme a interdit d'y entrer. La nuit, en passant au ralenti, Bruno entend frapper."},
	"cadenas": {"kind": "photo", "title": "Grille du local 14",
		"text": "Dans la boucle de Nation : une grille fermée par un cadenas neuf. Devant, des barquettes de repas vides. Derrière, quelqu'un respire."},
	"aveu_franck": {"kind": "temoignage", "title": "Aveux de Franck",
		"text": "Delorme a tout organisé. Karim est enfermé dans le local 14 depuis mardi : Delorme voulait savoir à qui il avait parlé, et récupérer ses photos du tunnel."},
}

const PROLOGUE := [
	{"from": "Nadia", "text": "Nation. Le terminus. J'arrive, je vous attends en haut, sur la place."},
	{"from": "Nadia", "text": "Je vous en prie. Ramenez-le."},
]

const DEDUCTIONS := [
	{
		"id": "local14",
		"question": "Où est Karim ?",
		"elements": ["temoignage_josiane", "temoignage_bruno", "cadenas", "registre_travaux"],
		"conclusions": [
			"Karim a été emmené hors de Paris, dans la camionnette blanche.",
			"Karim s'est caché de lui-même dans la boucle.",
			"Karim est enfermé dans le local 14 de la boucle de Nation, sur ordre de Delorme.",
		],
		"answer": 2,
		"success": "Le locotracteur l'a amené à Nation, le local 14 est cadenassé depuis mardi sur ordre de Delorme, et on y entend frapper. Karim est derrière cette grille.",
	},
]

const DIALOGUES := {
	"bruno": {
		"name": "Bruno",
		"nodes": {
			"debut": {"lines": ["(Un conducteur en veste RATP attend la rame de manœuvre au bout du quai.)",
				"Terminus, monsieur. Le prochain repart vers Porte Dauphine."], "goto": "hub"},
			"hub": {"choices": [
				["Vous conduisez les rames dans la boucle ?", "boucle", ""],
				["Il se passe quelque chose de bizarre, dans la boucle ?", "local", "!has:temoignage_bruno"],
				["Vous pourriez m'ouvrir la porte de service ?", "porte_non", "!porte_boucle"],
			]},
			"boucle": {"lines": ["Toute la nuit. On fait demi-tour par la boucle et on revient sur l'autre quai. Je la connais par cœur."]},
			"local": {"lines": ["Le local 14... Depuis mardi, cadenas neuf. Delorme a dit que personne n'y entre, « matériel dangereux ».",
				"Quand je passe au ralenti, la nuit, j'entends frapper. Je me suis dit que c'étaient les tuyaux."],
				"evidence": "temoignage_bruno"},
			"porte_non": {"lines": ["Sans une bonne raison, non. On ne se promène pas dans la boucle."]},
			"josiane": {"lines": ["(Il lit, et pâlit.)", "Un homme sur le wagon, vers Nation. Mardi.",
				"Les coups, dans le local 14... Ce n'étaient pas les tuyaux.", "(Il sort un passe de sa poche.)",
				"Je vous ouvre. Allez-y. Moi, je reste ici, je surveille le quai."], "set": ["porte_boucle"]},
			"ouverte": {"lines": ["C'est ouvert. Allez-y."]},
			"karim": {"lines": ["Benali ? On a débuté ensemble, sur la 2. On le cherche tous, ici, sans rien dire."]},
			"rien": {"lines": ["Je ne vois pas, monsieur."]},
		},
		"show": {"temoignage_josiane": [["!porte_boucle", "josiane"], ["", "ouverte"]], "karim": "karim", "default": "rien"},
	},
	"franck": {
		"name": "Franck",
		"nodes": {
			"debut": {"lines": ["(Un homme en gilet orange, assis sur un seau retourné, se lève d'un bond.)", "Qu'est-ce que vous faites là ? Dégagez."], "goto": "hub"},
			"hub": {"choices": [
				["Vous êtes Franck Roussel.", "nom", ""],
				["Ouvrez cette grille.", "ouvrir_non", "!franck_cede"],
				["C'est fini, Franck. Marchetti a parlé, et je sais qui est derrière cette grille.", "cede", "solved:local14 has:temoignage_marchetti !franck_cede"],
			]},
			"nom": {"lines": ["(Il serre les mâchoires.)", "Je ne vous connais pas."]},
			"ouvrir_non": {"lines": ["Il n'y a rien derrière. Du matériel. Partez."]},
			"marchetti": {"lines": ["Marchetti... Ce vieux lâche."]},
			"delorme": {"lines": ["C'est sa signature, pas la mienne. Moi, je conduis."]},
			"cede": {"lines": ["(Franck se rassoit sur son seau. Il a l'air épuisé.)",
				"C'était censé durer une nuit. Delorme voulait savoir à qui Benali avait parlé, et récupérer ses photos.",
				"Il ne dit rien. Ça fait une semaine qu'il ne dit rien.",
				"(Il vous tend une petite clé.)", "Moi, je n'ai jamais voulu ça."],
				"set": ["franck_cede"], "evidence": "aveu_franck"},
			"karim": {"lines": ["(Il détourne les yeux vers la grille.)"]},
			"rien": {"lines": ["Rien à dire."]},
		},
		"show": {"temoignage_marchetti": "marchetti", "livre_police": "marchetti", "registre_travaux": "delorme", "karim": "karim", "default": "rien"},
	},
	"karim": {
		"name": "Karim",
		"nodes": {
			"debut": {"lines": ["(Un homme amaigri, une couverture sur les épaules, cligne des yeux dans la lumière.)", "Qui... qui êtes-vous ?"], "goto": "hub"},
			"hub": {"choices": [
				["Je viens de la part de Nadia.", "nadia", "!karim_libre"],
				["Vous pouvez marcher ?", "marcher", "karim_libre"],
			]},
			"nadia": {"lines": ["Nadia...", "(Il ferme les yeux.)",
				"Je n'ai rien dit. À personne. Pour qu'ils la laissent tranquille.",
				"Mes photos du tunnel sont sous le siège de ma cabine. Le 040. Personne n'a pensé à regarder.",
				"Sortons d'ici."], "set": ["karim_libre"]},
			"marcher": {"lines": ["Appuyez-moi. On remonte."]},
			"rien": {"lines": ["(Il regarde, sans comprendre.)"]},
		},
		"show": {"default": "rien"},
	},
}

## Juste après minuit, après Jaurès.
const START := 24 * 60 + 15

const SEARCHES := [
	{"query": "local 14 boucle de Nation", "if": "has:temoignage_bruno", "results": [
		{"author": "Forum des cheminots", "time": "",
			"text": "Le 14 de la boucle de Nation ? Un ancien poste électrique, désaffecté depuis les années 1990. Plus personne n'y va.",
			"set": ["local14_desaffecte"]},
	]},
]

const HINT_DELAY := 600.0
const HINTS := [
	["!has:temoignage_bruno", "Les conducteurs font le tour de la boucle toute la nuit. Parlez à celui du bout du quai."],
	["!porte_boucle", "Montrez-lui ce qu'a vu Josiane, à Jaurès."],
	["!has:cadenas", "Il faut voir ce local 14 de vos yeux."],
	["!solved:local14", "Reliez ce que vous savez. Où est Karim ?"],
	["!franck_cede", "Cet homme a peur. Dites-lui que Marchetti a parlé, que vous savez tout."],
	["!karim_libre", "La grille est ouverte ? Allez-y. Je vous en supplie."],
]
