class_name Chapitre3
## Contenu du chapitre 3 (Pigalle) : le receleur. L'étiquette de la caisse mène à Antiquités
## Marchetti, rue Frochot. L'accordéoniste du couloir a vu passer les caisses ; le portier du
## Chat Rouge a vu la camionnette décharger chez l'antiquaire ; dans sa vitrine, la pendule
## volée boulevard Malesherbes. Confronté, Marchetti donne le nom de Franck Roussel et dit
## d'où partent les caisses : le dépôt des trains de travaux, sous le viaduc de Jaurès.

const STATION := "Pigalle"

const EVIDENCE := {
	"vitrine": {"kind": "photo", "title": "Vitrine d'Antiquités Marchetti",
		"text": "Rue Frochot, dans la vitrine éclairée de l'antiquaire : une pendule en bronze doré, la même que sur l'avis de vol du boulevard Malesherbes."},
	"temoignage_remi": {"kind": "temoignage", "title": "Témoignage de Rémi, accordéoniste",
		"text": "Le vendredi, à la fermeture, des hommes en gilet orange remontent du quai avec un diable chargé de caisses, vers la sortie du boulevard. L'un d'eux lui donne un billet pour qu'il regarde ailleurs."},
	"temoignage_lulu": {"kind": "temoignage", "title": "Témoignage de Lulu, portier",
		"text": "Le vendredi vers 4 h, une camionnette blanche sans logo, plaque en GH-, se gare devant chez Marchetti, rue Frochot. Un homme en gilet orange décharge des caisses ; l'antiquaire lui ouvre."},
	"livre_police": {"kind": "indice", "title": "Livre de police de Marchetti",
		"text": "Le registre que tout antiquaire doit tenir : une vingtaine d'objets achetés depuis septembre à « F. Roussel », sans facture ni provenance, payés en liquide. Le dernier : une danseuse en bronze."},
	"temoignage_marchetti": {"kind": "temoignage", "title": "Aveux de Marchetti",
		"text": "Franck Roussel, ancien sous-traitant de la RATP, lui apporte les objets. Franck obéit à un « chef » de la maintenance dont il ne dit pas le nom. Les caisses partent du dépôt des trains de travaux, sous le viaduc de Jaurès."},
}

const PROLOGUE := [
	{"from": "Nadia", "text": "Pigalle. Je n'ai pas fermé l'œil. Inès m'a appelée : elle a peur pour vous."},
	{"from": "Nadia", "text": "La rue Frochot part de la place Pigalle. Cet antiquaire n'ouvre que sur rendez-vous, paraît-il."},
]

const DEDUCTIONS := [
	{
		"id": "receleur",
		"question": "Quel est le rôle de Marchetti ?",
		"elements": ["caisse", "avis_vol", "vitrine", "temoignage_lulu"],
		"conclusions": [
			"Marchetti a été cambriolé lui aussi : la pendule est à lui.",
			"Les caisses sont arrivées chez Marchetti par erreur.",
			"Marchetti écoule les objets volés que l'homme au gilet orange lui livre la nuit.",
		],
		"answer": 2,
		"success": "La caisse porte son adresse, la pendule volée est dans sa vitrine, et la camionnette décharge chez lui le vendredi. Marchetti est le receleur. Il est temps de lui parler franchement.",
	},
]

const DIALOGUES := {
	"marchetti": {
		"name": "Marchetti",
		"nodes": {
			"debut": {"lines": ["(Un homme en gilet de laine compte des étiquettes derrière sa porte entrouverte.)",
				"C'est fermé. Revenez demain, sur rendez-vous."], "goto": "hub"},
			"hub": {"choices": [
				["Vous vendez des objets d'art ?", "objets", ""],
				["Une livraison, la nuit, ça vous arrive ?", "livraison", ""],
				["Je sais d'où vient votre pendule.", "aveu", "solved:receleur !marchetti_aveu"],
				["Parlez-moi de l'homme au gilet orange.", "franck", "marchetti_aveu !marchetti_jaures"],
			]},
			"objets": {"lines": ["Des objets anciens, monsieur. Des successions, des greniers.", "Tout est en règle. J'ai mon livre de police, comme la loi l'exige."]},
			"livraison": {"lines": ["La nuit ? Je dors, la nuit."]},
			"caisse": {"lines": ["(Il regarde l'étiquette à son nom et ne dit rien.)", "Des caisses à mon nom, n'importe qui peut en écrire. Ça ne prouve rien."], "set": ["marchetti_caisse"]},
			"avis": {"lines": ["Une danseuse en bronze... Ça court les rues, ce genre de modèle."]},
			"vitrine": {"lines": ["Cette pendule ? Achetée dans une succession, à Neuilly. J'ai les papiers. Quelque part."]},
			"lulu": {"lines": ["Lulu ? Lulu boit trop. Il voit des camionnettes partout."]},
			"aveu": {"lines": ["(Marchetti s'assoit sur une malle et se frotte le visage.)",
				"Il s'appelle Franck. Franck Roussel. Il travaillait pour un sous-traitant de la RATP, avant.",
				"Il m'apporte des pièces depuis septembre. Je ne pose pas de questions, je paie en liquide. Tout est noté, regardez.",
				"(Il vous tend un registre relié de toile.)"],
				"set": ["marchetti_aveu"], "evidence": "livre_police"},
			"franck": {"lines": ["Franck ne décide de rien. Il parle d'un « chef », à la RATP. Il ne m'a jamais dit son nom.",
				"Les caisses partent d'un dépôt de trains de travaux. Sous le viaduc, à Jaurès.",
				"S'ils apprennent que je vous ai parlé...", "(Il ferme la porte à clé derrière vous.)"],
				"set": ["marchetti_jaures"], "evidence": "temoignage_marchetti"},
			"karim": {"lines": ["Je ne connais pas ce monsieur. Je vous le jure."]},
			"rien": {"lines": ["Je ne vois pas ce que vous voulez dire."]},
		},
		"show": {"caisse": "caisse", "avis_vol": "avis", "vitrine": "vitrine", "temoignage_lulu": "lulu", "karim": "karim", "default": "rien"},
	},
	"lulu": {
		"name": "Lulu",
		"nodes": {
			"debut": {"lines": ["(Un colosse en costume noir garde la porte du Chat Rouge.)", "Complet, mon grand. Repasse plus tard."], "goto": "hub"},
			"hub": {"choices": [
				["Je ne viens pas pour le spectacle.", "pas_spectacle", "!lulu_parle"],
				["Vous connaissez l'antiquaire de la rue Frochot ?", "marchetti", "lulu_parle"],
				["Une camionnette blanche, ça vous dit quelque chose ?", "camionnette", "lulu_parle !has:temoignage_lulu"],
			]},
			"pas_spectacle": {"lines": ["Alors tu veux quoi ? Moi, je garde une porte. Je regarde la rue toute la nuit."], "set": ["lulu_parle"]},
			"marchetti": {"lines": ["Marchetti ? Le vieux aux pendules. Il ne vend rien, sa boutique est toujours fermée.", "Et pourtant il roule en grosse voiture."]},
			"camionnette": {"lines": ["Le vendredi, vers quatre heures, une camionnette blanche sans logo se gare devant chez lui.",
				"Plaque en GH, je m'en souviens : c'est mes initiales. Gérard Hubert.",
				"Un type en gilet orange décharge des caisses, et Marchetti lui ouvre en robe de chambre."],
				"set": ["lulu_camionnette"], "evidence": "temoignage_lulu"},
			"voyageur": {"lines": ["Le gilet orange... C'est lui, le livreur du vendredi."], "set": ["lulu_gilet"]},
			"rien": {"lines": ["Connais pas. Et je ne regarde pas les photos des clients."]},
		},
		"show": {"photo_voyageur": "voyageur", "default": "rien"},
	},
	"remi": {
		"name": "Rémi",
		"nodes": {
			"debut": {"lines": ["(Un accordéoniste joue « La Javanaise » pour le couloir vide.)", "Une pièce pour la musique ?"], "goto": "hub"},
			"hub": {"choices": [
				["(Donner une pièce.)", "piece", "!remi_piece"],
				["Vous jouez ici tous les soirs ?", "soirs", ""],
				["Vous voyez passer les gars de la maintenance ?", "maintenance", "remi_piece !remi_parle"],
			]},
			"piece": {"lines": ["Merci, merci. Les gens ne donnent plus, avec les cartes."], "set": ["remi_piece"]},
			"soirs": {"lines": ["Jusqu'au dernier métro. Après, on me met dehors.", "Sauf le vendredi : le vendredi, on me met dehors plus tôt."]},
			"maintenance": {"lines": ["Les gilets orange ? Le vendredi, à la fermeture. Ils remontent du quai avec un diable chargé de caisses, vers le boulevard.",
				"Il y en a un qui me donne toujours un billet pour que je regarde ailleurs. Alors je regarde ailleurs."],
				"set": ["remi_parle"], "evidence": "temoignage_remi"},
			"voyageur": {"lines": ["C'est lui, le généreux. Une camionnette l'attend en haut, je crois."]},
			"rien": {"lines": ["(Il hausse les épaules et reprend son air.)"]},
		},
		"show": {"photo_voyageur": "voyageur", "default": "rien"},
	},
}

## Le lendemain soir.
const START := 22 * 60 + 40

const SEARCHES := [
	{"query": "Antiquités Marchetti rue Frochot", "if": "", "results": [
		{"author": "Avis en ligne · ★★☆☆☆", "time": "il y a 3 mois",
			"text": "Boutique toujours fermée. « Sur rendez-vous », qu'ils disent. Personne ne répond au téléphone."},
	]},
	{"query": "livre de police antiquaire", "if": "", "results": [
		{"author": "Service-public.fr", "time": "",
			"text": "Les antiquaires doivent tenir un registre, le « livre de police », où ils notent chaque objet acheté, son vendeur et sa provenance.",
			"set": ["livre_police_connu"]},
	]},
	{"query": "Franck Roussel RATP", "if": "marchetti_aveu", "results": [
		{"author": "Le Parisien · 2019", "time": "",
			"text": "Un ancien sous-traitant de la RATP condamné à huit mois avec sursis pour un vol de câbles de cuivre sur la ligne 2.",
			"set": ["roussel_casier"]},
	]},
]

const HINT_DELAY := 600.0
const HINTS := [
	["!has:vitrine", "La rue Frochot part de la place Pigalle. Allez voir cette boutique, même fermée."],
	["!remi_parle", "Il y a un musicien dans le couloir de la station. Les musiciens voient tout passer."],
	["!has:temoignage_lulu", "Les portiers de Pigalle regardent la rue toute la nuit. Quelqu'un a forcément vu ces livraisons."],
	["!solved:receleur", "Vous avez de quoi relier les pièces. Faites-le dans vos déductions."],
	["!marchetti_aveu", "L'antiquaire. Mettez-le face à ce que vous savez."],
	["!marchetti_jaures", "Demandez-lui qui est cet homme au gilet orange, et d'où partent les caisses."],
	["marchetti_jaures", "Jaurès... Reprenez la 2, direction Nation. Je vous en supplie, soyez prudent."],
]
