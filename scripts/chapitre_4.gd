class_name Chapitre4
## Contenu du chapitre 4 (Jaurès) : l'homme de l'intérieur. Sous le viaduc, le dépôt des trains
## de travaux : Sami, un agent de maintenance honnête, ouvre le portail quand on lui montre le
## planning signé « M. D. » ; dedans, le locotracteur chargé de caisses et, dans le bureau de
## chantier, le registre signé Delorme. La déduction faite, Delorme ne nie plus vraiment, et
## menace. Josiane, l'agente de station, a vu le locotracteur emmener Karim vers Nation.

const STATION := "Jaurès"

const EVIDENCE := {
	"temoignage_sami": {"kind": "temoignage", "title": "Témoignage de Sami",
		"text": "Les « interventions » du mardi et du vendredi à Villiers n'existent pas : aucune équipe, aucun bon de chantier. Delorme part seul avec le locotracteur et un homme d'un sous-traitant."},
	"draisine": {"kind": "photo", "title": "Locotracteur chargé",
		"text": "Au dépôt sous le viaduc de Jaurès : le locotracteur jaune « TRAVAUX » et son wagon plat, chargé de caisses neuves « Fragile – Objets d'art » sous une bâche."},
	"registre_travaux": {"kind": "photo", "title": "Registre des trains de travaux",
		"text": "Dans le bureau de chantier : chaque mardi et chaque vendredi, « intervention voie de garage de Villiers – locotracteur 4 », signée M. Delorme. Aucun bon de chantier."},
	"temoignage_josiane": {"kind": "temoignage", "title": "Témoignage de Josiane",
		"text": "Le soir de la disparition, vers 0 h 30, le locotracteur jaune est passé à Jaurès vers Nation. Un homme était assis sur le wagon, la tête basse : Karim."},
}

const PROLOGUE := [
	{"from": "Nadia", "text": "Jaurès. C'est là que la ligne sort de terre. Karim aimait ce moment : il disait qu'on y voyait enfin le ciel."},
	{"from": "Nadia", "text": "Inès dit que les trains de travaux dorment dans un dépôt, sous le viaduc. Delorme y passe ses nuits."},
]

const DEDUCTIONS := [
	{
		"id": "delorme",
		"question": "Qui organise le trafic ?",
		"elements": ["planning_travaux", "registre_travaux", "draisine", "temoignage_sami"],
		"conclusions": [
			"Franck agit seul, à l'insu de Delorme.",
			"Les trains de travaux sont de vrais chantiers : les caisses sont du matériel de la RATP.",
			"Delorme invente de faux chantiers pour faire rouler le locotracteur chargé du butin.",
		],
		"answer": 2,
		"success": "Le planning signé « M. D. », le registre, le locotracteur chargé et le témoignage de Sami : Marc Delorme est l'homme de l'intérieur. Reste à le lui dire en face.",
	},
]

const DIALOGUES := {
	"sami": {
		"name": "Sami",
		"nodes": {
			"debut": {"lines": ["(Un agent en gilet orange fume devant la grille du dépôt, sous le viaduc.)", "C'est fermé, ici. Zone RATP."], "goto": "hub"},
			"hub": {"choices": [
				["Vous travaillez pour Delorme ?", "delorme", ""],
				["Il y a des chantiers, cette nuit ?", "chantiers", "!has:temoignage_sami"],
				["Vous pourriez m'ouvrir ?", "ouvrir_non", "!depot_ouvert"],
			]},
			"delorme": {"lines": ["Delorme, c'est mon chef d'équipe. Toujours le sourire, toujours une prime pour ceux qui ne posent pas de questions."]},
			"chantiers": {"lines": ["Officiellement ? Tous les mardis et vendredis, voie de garage de Villiers.",
				"Sauf qu'on n'y envoie jamais personne. Pas une équipe, pas un bon de chantier.",
				"Delorme part seul avec le locotracteur et un gars d'un sous-traitant."], "evidence": "temoignage_sami"},
			"ouvrir_non": {"lines": ["Sans raison ? Non. Si Delorme vous trouve là-dedans, c'est moi qui saute."]},
			"planning": {"lines": ["(Il regarde la photo longtemps.)", "« M. D. »... Il signe même ses mensonges.",
				"Je ne vais pas couvrir ça. Entrez. Le bureau est au fond, il y est ce soir."], "set": ["depot_ouvert"]},
			"ouvert": {"lines": ["C'est ouvert. Faites vite."]},
			"karim": {"lines": ["Benali ? Un type bien. Il m'avait demandé, une fois, qui travaillait la nuit à Villiers. Je lui ai dit : personne."]},
			"franck": {"lines": ["Roussel ? Il traîne ici le vendredi. Il n'a plus de badge depuis deux ans, mais Delorme le fait entrer."], "set": ["sami_franck"]},
			"rien": {"lines": ["Connais pas."]},
		},
		"show": {"planning_travaux": [["!depot_ouvert", "planning"], ["", "ouvert"]], "karim": "karim",
			"temoignage_marchetti": "franck", "livre_police": "franck", "default": "rien"},
	},
	"delorme": {
		"name": "Delorme",
		"nodes": {
			"debut": {"lines": ["(Un homme en chemise blanche, gilet orange sur les épaules, range des classeurs. Il sourit.)",
				"Vous êtes perdu ? Ici, c'est un dépôt technique."], "goto": "hub"},
			"hub": {"choices": [
				["Je travaille pour la famille de Karim Benali.", "benali", ""],
				["Ces trains de travaux, le mardi et le vendredi ?", "travaux", ""],
				["Je sais ce que transporte votre locotracteur.", "confrontation", "solved:delorme !delorme_confronte"],
			]},
			"benali": {"lines": ["Benali. Un malaise, puis un départ volontaire. J'ai signé le rapport moi-même.", "C'est triste, mais ça arrive."]},
			"travaux": {"lines": ["De l'entretien de voie. C'est la nuit qu'on travaille, sinon les voyageurs se plaignent."]},
			"signalement": {"lines": ["(Son sourire se fige une seconde.)", "Je reçois des dizaines de notes. Benali voyait des fantômes dans les tunnels. La fatigue."], "set": ["delorme_note"]},
			"franck": {"lines": ["Roussel ? Ce nom ne me dit rien."], "set": ["delorme_ment"]},
			"confrontation": {"lines": ["(Delorme referme lentement le classeur.)",
				"Un locotracteur, des caisses, un antiquaire... Vous avez beaucoup d'imagination.",
				"Vous croyez qu'on vous écoutera ? Moi, j'ai vingt-cinq ans de maison. Vous, vous n'avez rien.",
				"Benali aussi croyait qu'on l'écouterait. Il a eu de la chance, lui. Pour l'instant.",
				"(Il se lève et vous montre la porte.)"], "set": ["delorme_confronte"]},
			"rien": {"lines": ["Je n'ai pas de temps pour ça."]},
		},
		"show": {"signalement": "signalement", "temoignage_marchetti": "franck", "livre_police": "franck", "default": "rien"},
	},
	"josiane": {
		"name": "Josiane",
		"nodes": {
			"debut": {"lines": ["(Une agente de station fait sa ronde sur le quai, lampe torche à la main.)", "Le dernier passe bientôt, monsieur."], "goto": "hub"},
			"hub": {"choices": [
				["Vous étiez de service mardi soir ?", "mardi", ""],
				["Vous voyez passer des trains de travaux ?", "draisine", "!has:temoignage_josiane"],
			]},
			"mardi": {"lines": ["Oui, jusqu'à la fermeture. Il ne se passe jamais rien à Jaurès après minuit."]},
			"draisine": {"lines": ["Le locotracteur jaune ? Le mardi et le vendredi, vers une heure.",
				"Mardi, il est passé plus tôt, vers minuit et demi, direction Nation. Il y avait quelqu'un assis sur le wagon, la tête basse.",
				"Je me suis dit qu'un gars avait trop bu."], "set": ["josiane_mardi"]},
			"karim": {"lines": ["(Elle éclaire la photo avec sa lampe.)", "...C'était lui. Sur le wagon, mardi. Mon Dieu, c'était lui.",
				"Il levait la tête vers le ciel. Comme s'il voulait le voir une dernière fois."], "evidence": "temoignage_josiane"},
			"karim_avant": {"lines": ["Le conducteur de Monceau ? On en a parlé. Je ne le connaissais pas."]},
			"photo": {"lines": ["C'est celui-là. Il n'aurait pas dû rouler ce soir-là : il n'y avait aucun chantier."]},
			"rien": {"lines": ["Je ne sais pas, monsieur."]},
		},
		"show": {"karim": [["josiane_mardi", "karim"], ["", "karim_avant"]], "draisine": "photo", "default": "rien"},
	},
}

## Le même soir, après Pigalle.
const START := 23 * 60 + 30

const SEARCHES := [
	{"query": "Marc Delorme RATP", "if": "", "results": [
		{"author": "Réseau professionnel", "time": "",
			"text": "Marc Delorme · Chef d'équipe, maintenance des voies, ligne 2 · RATP · 25 ans d'expérience. « Toujours au service des voyageurs. »"},
	]},
	{"query": "trains de travaux RATP la nuit", "if": "", "results": [
		{"author": "RATP · Les coulisses du métro", "time": "",
			"text": "Chaque nuit, des trains de travaux circulent sur le réseau. Chaque circulation fait l'objet d'un bon de chantier, validé par le poste de commande.",
			"set": ["bon_chantier"]},
	]},
	{"query": "terminus de Nation ligne 2", "if": "has:temoignage_josiane", "results": [
		{"author": "Wikipédia", "time": "",
			"text": "À Nation, la ligne 2 fait demi-tour par une boucle souterraine, avec ses voies de service et ses locaux techniques.",
			"set": ["boucle_nation"]},
	]},
]

const HINT_DELAY := 600.0
const HINTS := [
	["!has:temoignage_sami", "Le dépôt est sous le viaduc, vers l'est. Quelqu'un doit le garder, la nuit."],
	["!depot_ouvert", "Montrez à cet agent le planning que vous avez trouvé à Villiers. Il a peut-être des scrupules."],
	["!has:draisine", "Si les caisses passent par ce dépôt, elles y sont peut-être encore."],
	["!has:registre_travaux", "Delorme note tout, paraît-il. Son bureau est au fond du dépôt."],
	["!solved:delorme", "Vous avez de quoi relier les pièces. Faites-le dans vos déductions."],
	["!delorme_confronte", "Delorme. Dites-lui ce que vous savez, en face."],
	["!has:temoignage_josiane", "L'agente du quai voit passer tous les trains. Montrez-lui la photo de Karim."],
	["has:temoignage_josiane", "Nation... Karim est peut-être encore là-bas. Reprenez la 2, direction Nation. Vite."],
]
