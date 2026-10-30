class_name Chapitre2
## Contenu du chapitre 2 (Villiers) : le tunnel entre Monceau et Villiers sert d'entrepôt, et la
## marchandise voyage la nuit sur les trains de travaux. Karim l'avait vu et l'avait écrit à
## Delorme, à la maintenance (voir docs/document_de_conception.md, « La vérité sur Karim »).
##
## Déroulé : Inès, au café de la rue de Lévis, raconte les lumières dans le tunnel et donne le
## double du signalement de Karim ; montré à l'agent de sécurité de la salle des billets, il
## lui fait ouvrir le local technique de la ligne 3 (planning des trains de travaux) ; derrière,
## la boucle désaffectée, une caisse d'objets d'art dans une vieille voiture, et Franck qui
## s'enfuit. L'avis de vol se trouve en ligne, en surface. La déduction faite, on reprend la 2
## direction Nation : l'étiquette de la caisse mène à Pigalle.

const STATION := "Villiers"

const EVIDENCE := {
	"temoignage_ines": {"kind": "temoignage", "title": "Témoignage d'Inès",
		"text": "Les dernières semaines, Karim voyait des lumières et entendait des voix dans le tunnel entre Monceau et Villiers, après le dernier métro. Aucun chantier n'était prévu."},
	"signalement": {"kind": "indice", "title": "Signalement de Karim",
		"text": "Double d'une note de Karim à M. Delorme, chef d'équipe à la maintenance des voies : « Lumières et mouvements dans le tunnel entre Monceau et Villiers, après la fin du service, trois nuits ce mois-ci. » Gardé par Inès. Une semaine après, Karim disparaissait."},
	"temoignage_gpsr": {"kind": "temoignage", "title": "Témoignage de l'agent de sécurité",
		"text": "Certaines nuits, ses rondes à Villiers sont annulées par la maintenance : « travaux, accès interdit ». Les mardis et les vendredis."},
	"planning_travaux": {"kind": "photo", "title": "Planning des trains de travaux",
		"text": "Punaisé dans le local technique de la ligne 3 : « Trains de travaux, voie de garage de Villiers, mardi et vendredi, 1 h 30 – 4 h ». Signé « M. D. »."},
	"caisse": {"kind": "photo", "title": "Caisse d'objets d'art",
		"text": "Dans une vieille voiture Sprague de la boucle désaffectée : une caisse neuve, « Fragile – Objets d'art », une statuette de bronze dans du papier bulle. Étiquette d'expédition : Antiquités Marchetti, rue Frochot, Paris 9e."},
	"avis_vol": {"kind": "photo", "title": "Avis de vol",
		"text": "Volées le 3 novembre dans un appartement du boulevard Malesherbes, avec une collection d'objets d'art : une danseuse en bronze de la fin du XIXe siècle et une pendule en bronze doré. Trouvé en ligne."},
	"ticket": {"kind": "indice", "title": "Ticket de carte bancaire",
		"text": "Laissé au café Le Lévis par l'homme au gilet orange : quatre cafés, mardi 22 h 41, payés par la carte de « TVR Services », une société de sous-traitance ferroviaire."},
}

## Messages reçus en arrivant à Villiers.
const PROLOGUE := [
	{"from": "Nadia", "text": "Villiers, alors. Karim avait une amie, Inès, conductrice sur la 2. Elle finit tard et passe au café en face de la station, rue de Lévis."},
	{"from": "Nadia", "text": "Dites-lui que vous venez de ma part. Et faites attention à vous."},
]

const DEDUCTIONS := [
	{
		"id": "trafic",
		"question": "Pourquoi a-t-on fait disparaître Karim ?",
		"elements": ["signalement", "caisse", "avis_vol", "planning_travaux"],
		"conclusions": [
			"Karim a surpris des tagueurs dans le tunnel et il a pris peur.",
			"Karim faisait partie du trafic et il s'est enfui avec le butin.",
			"Karim a vu le trafic et l'a signalé : on l'a enlevé, et quelqu'un de la maintenance couvre l'affaire.",
		],
		"answer": 2,
		"success": "Les objets volés dorment dans la boucle et partent les nuits des faux trains de travaux, signés « M. D. ». Karim l'avait vu et l'avait écrit à Delorme. L'étiquette de la caisse mène à Pigalle, rue Frochot.",
	},
]

## Dialogues (même format que Chapitre1.DIALOGUES).
const DIALOGUES := {
	"ines": {
		"name": "Inès",
		"nodes": {
			"debut": {"lines": ["(Une femme en veste de la RATP fume, seule à une table de la terrasse.)",
				"Si vous êtes journaliste, je n'ai rien à dire."], "goto": "hub"},
			"hub": {"choices": [
				["Je viens de la part de Nadia Benali, la sœur de Karim.", "nadia", "!ines_confiance"],
				["Karim vous parlait de son travail ?", "lumieres", "ines_confiance !ines_lumieres"],
				["Il a fait quelque chose, pour ces lumières ?", "signalement", "ines_lumieres !has:signalement"],
				["Qui est Delorme ?", "delorme", "has:signalement !delorme_nom"],
			]},
			"nadia": {"lines": ["Nadia... Il parlait d'elle tout le temps.", "(Elle écrase sa cigarette.)",
				"Karim, c'est mon binôme depuis quinze ans. Personne ne veut m'écouter, à la RATP."], "set": ["ines_confiance"]},
			"lumieres": {"lines": ["Les dernières semaines, il voyait des lumières dans le tunnel, entre Monceau et Villiers. Après le dernier métro, quand il ramenait la rame.",
				"Des lampes qui bougent, des voix. Aucun chantier prévu. Ça le rendait fou."],
				"set": ["ines_lumieres"], "evidence": "temoignage_ines"},
			"signalement": {"lines": ["Il l'a écrit. Une note à son responsable de maintenance. Il m'en a laissé un double, au cas où.",
				"(Elle sort une feuille pliée de son sac.)", "Tenez. Une semaine après, il disparaissait."],
				"evidence": "signalement"},
			"delorme": {"lines": ["Marc Delorme. Chef d'équipe à la maintenance des voies. Un type qui sourit tout le temps.",
				"C'est lui qui a signé le rapport du « malaise ». Je l'ai vu affiché au dépôt."], "set": ["delorme_nom"]},
			"karim": {"lines": ["(Elle regarde longtemps la photo.)", "Il disait qu'il finirait sa carrière sur la 2. Il aimait cette ligne."]},
			"voyageur": {"lines": ["Un gilet orange... Ils en ont tous, à la maintenance.",
				"Mais celui-là, je l'ai déjà vu ici, au café. Demandez au patron."], "set": ["ines_gilet"]},
			"caisse": {"lines": ["(Elle pâlit.)", "Dans la boucle ? C'est là qu'il voyait les lumières. Karim avait raison."]},
			"rien": {"lines": ["Ça ne me dit rien."]},
		},
		"show": {"karim": "karim", "photo_voyageur": "voyageur", "caisse": "caisse", "default": "rien"},
	},
	"patron": {
		"name": "Le patron",
		"nodes": {
			"debut": {"lines": ["(Le patron du café empile les chaises de la terrasse.)", "On ferme à une heure. Un café ?"], "goto": "hub"},
			"hub": {"choices": [
				["Un café, oui.", "cafe", ""],
				["Vous voyez passer les équipes de nuit ?", "equipes", ""],
			]},
			"cafe": {"lines": ["(Il revient avec une tasse brûlante.)", "Un euro quarante. Le dernier prix honnête du quartier."], "set": ["cafe_bu"]},
			"equipes": {"lines": ["Les gars de la RATP ? Tous les soirs.",
				"Ceux de la maintenance, surtout le mardi et le vendredi. Ils commandent, ils paient, ils descendent."], "set": ["patron_equipes"]},
			"voyageur": {"lines": ["Lui, je le connais. Il paie toujours pour quatre, toujours avec la même carte.",
				"Mardi, il a oublié son ticket sur la table. Je garde tout, moi.", "(Il fouille sous le comptoir et vous le tend.)"],
				"set": ["patron_ticket"], "evidence": "ticket"},
			"deja": {"lines": ["Je vous ai déjà donné son ticket. Le reste, ça ne me regarde pas."]},
			"karim": {"lines": ["Le conducteur ? Il venait le matin, avant son service. Un grand crème, toujours."]},
			"rien": {"lines": ["Connais pas."]},
		},
		"show": {"photo_voyageur": [["!patron_ticket", "voyageur"], ["", "deja"]], "karim": "karim", "default": "rien"},
	},
	"gpsr": {
		"name": "L'agent de sécurité",
		"nodes": {
			"debut": {"lines": ["(Un agent de la sûreté RATP, gilet pare-balles sur le dos, surveille les portillons.)",
				"Bonsoir. Contrôle des titres de transport."], "goto": "hub"},
			"hub": {"choices": [
				["J'enquête sur Karim Benali, le conducteur.", "karim", ""],
				["Vos rondes passent par la ligne 3 ?", "rondes", "!gpsr_rondes"],
				["Vous pourriez m'ouvrir le local technique de la ligne 3 ?", "local_non", "!local_ouvert"],
			]},
			"karim": {"lines": ["Le conducteur de Monceau. On en a parlé au briefing. Officiellement, c'est un malaise."]},
			"rondes": {"lines": ["Normalement, toutes les nuits, jusqu'à la boucle. Mais certaines nuits, on nous annule le secteur : « travaux, accès interdit ».",
				"Les mardis et les vendredis. Ordre de la maintenance. On ne discute pas."],
				"set": ["gpsr_rondes"], "evidence": "temoignage_gpsr"},
			"local_non": {"lines": ["Sans une bonne raison, non. Et je ne vous connais pas."]},
			"local_oui": {"lines": ["(Il lit la note deux fois.)", "Des lumières dans le tunnel... Les nuits où on m'annule mes rondes.",
				"Je vous ouvre le local. Mais vous ne m'avez jamais vu, d'accord ?"], "set": ["local_ouvert"]},
			"ouvert": {"lines": ["C'est ouvert. Faites vite, et ne touchez à rien."]},
			"rien": {"lines": ["Je ne peux rien vous dire là-dessus."]},
		},
		"show": {"signalement": [["!local_ouvert", "local_oui"], ["", "ouvert"]], "karim": "karim", "default": "rien"},
	},
}

## Le chapitre reprend la même nuit, à l'arrivée à Villiers.
const START := 23 * 60 + 40

const SEARCHES := [
	{"query": "travaux de nuit ligne 2 Villiers", "if": "", "results": [
		{"author": "RATP · Info travaux", "time": "novembre",
			"text": "Aucun chantier de nuit n'est programmé ce mois-ci sur les lignes 2 et 3 à Villiers.", "set": ["aucun_chantier"]},
	]},
	{"query": "statuette bronze volée boulevard Malesherbes", "if": "has:caisse", "results": [
		{"author": "Le Parisien · 17e", "time": "5 novembre",
			"text": "Cambriolage boulevard Malesherbes : une collection d'objets d'art dérobée, dont une danseuse en bronze de la fin du XIXe siècle et une pendule en bronze doré. Aucune trace d'effraction.",
			"evidence": "avis_vol"},
	]},
	{"query": "TVR Services", "if": "has:ticket", "results": [
		{"author": "Annuaire des entreprises", "time": "",
			"text": "TVR Services, SARL, sous-traitance ferroviaire. Gérant : Franck R. Société radiée il y a deux ans ; l'adresse est une boîte postale à Pigalle.",
			"set": ["tvr_franck"]},
	]},
]

const HINT_DELAY := 600.0
const HINTS := [
	["!ines_confiance", "Inès doit être au café de la rue de Lévis. Dites-lui que vous venez de ma part."],
	["!has:signalement", "Inès sait des choses. Demandez-lui ce que Karim lui racontait."],
	["!local_ouvert", "Karim parlait d'un local, sur le quai de la ligne 3. Il faut quelqu'un qui en a la clé : la sécurité, peut-être ?"],
	["!has:planning_travaux", "Si on vous a ouvert ce local, regardez bien les murs."],
	["!has:caisse", "Derrière le local, il y a une vieille voie, une boucle. C'est là que Karim voyait les lumières."],
	["!has:avis_vol", "Ce qu'il y a dans cette caisse vient forcément de quelque part. Cherchez en ligne, en surface."],
	["!solved:trafic", "Vous avez de quoi relier les pièces. Faites-le dans vos déductions."],
	["solved:trafic", "Pigalle... Reprenez la 2, direction Nation."],
]
