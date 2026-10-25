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
	"temoignage_roche": {"kind": "temoignage", "title": "Témoignage de Mme Roche",
		"text": "Une camionnette blanche sans logo garée devant la Rotonde vers 23 h, moteur allumé. Repartie vers la rue de Monceau."},
	"temoignage_gardien": {"kind": "temoignage", "title": "Témoignage du gardien",
		"text": "Deux hommes sont remontés de la station vers 23 h 15 et sont partis vers la rue de Monceau. L'un tenait l'autre par le bras."},
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


## Dialogues. Chaque personnage a des nœuds : `lines` (répliques ; entre parenthèses, ce que
## voit le détective), `choices` (questions du joueur), `goto` (nœud suivant ; sinon retour au
## nœud « hub »), `if` (condition, voir Enquete.check), `set` et `evidence` (effets).
## `show` : réaction quand on montre une pièce du dossier (clé = pièce, « default » sinon) ;
## une valeur peut être une liste de [condition, nœud] essayées dans l'ordre.
## Un personnage ment tant qu'on ne le contredit pas avec la bonne pièce.
const DIALOGUES := {
	"sylvain": {
		"name": "Sylvain",
		"nodes": {
			"debut": {"lines": ["(L'agent de station lève à peine les yeux.)",
				"Le dernier métro passe à une heure. Vous cherchez quelque chose ?"], "goto": "hub"},
			"hub": {"choices": [
				["Vous étiez là mardi soir, à 23 h 12 ?", "pause", "!sylvain_pause"],
				["Votre pause, c'était à quelle heure, déjà ?", "pause", "sylvain_pause !sylvain_ment"],
				["Qu'est-ce qui s'est passé, d'après vous ?", "malaise", ""],
				["Les caméras ont été coupées quatre minutes.", "cameras", "sylvain_pause"],
				["Je sais ce qui s'est passé à 23 h 12.", "aveu", "solved:faux_agent !sylvain_aveu"],
			]},
			"pause": {"lines": ["Mardi ? J'étais en pause. De 23 heures à 23 heures 30, comme tous les soirs.",
				"Quand je suis revenu, la rame était à quai, portes ouvertes. Plus de conducteur."], "set": ["sylvain_pause"]},
			"malaise": {"lines": ["Un malaise, c'est ce qu'a dit la direction. Et après il est parti de lui-même.",
				"Vingt ans de conduite, ça use. Ça arrive, vous savez."]},
			"cameras": {"lines": ["Les caméras, c'est pas mon rayon. Ce système plante tout le temps."]},
			"cahier_avant": {"lines": ["Mon cahier ? C'est du service, ça. Rendez-le-moi."]},
			"cahier": {"lines": ["(Il regarde la page du soir. « Intervention maintenance, 23 h 08. »)",
				"C'est mon écriture, oui. Et alors ?",
				"...Bon. J'étais pas en pause. Mais j'ai rien vu, je vous dis."], "set": ["sylvain_ment"]},
			"badge": {"lines": ["(Il blêmit en voyant le badge.)", "Où vous avez trouvé ça ? Je sais rien, moi."]},
			"serrure": {"lines": ["Cette porte est toujours fermée. Y a que la maintenance qui a la clé."], "set": ["sylvain_cle"]},
			"voyageur": {"lines": ["(Son regard s'arrête sur le gilet orange.)",
				"La maintenance passe souvent le soir. Je les connais pas tous."]},
			"karim": {"lines": ["Benali ? Je le connais de vue. Un gars correct. Ça m'a fait de la peine."]},
			"aveu": {"lines": ["(Sylvain se tait longtemps.)",
				"Un type en gilet orange. Il m'a donné une enveloppe, à huit heures. Il m'a dit de regarder ailleurs. Une intervention, soi-disant.",
				"J'ai rien fait à Karim. Je voulais pas savoir.",
				"Le type a parlé d'un local à Villiers. C'est tout ce que je sais. Je vous jure."],
				"set": ["sylvain_aveu"]},
			"rien": {"lines": ["Je vois pas ce que vous voulez que je vous dise."]},
		},
		"show": {
			"cahier": [["sylvain_pause", "cahier"], ["", "cahier_avant"]],
			"badge": "badge", "serrure": "serrure", "photo_voyageur": "voyageur", "karim": "karim",
			"default": "rien",
		},
	},
	"jo": {
		"name": "Jo",
		"nodes": {
			"debut": {"lines": ["(Un homme dort contre le mur, enroulé dans une couverture.)", "Mmh... Laissez-moi dormir."], "goto": "hub"},
			"hub": {"choices": [
				["Vous dormez souvent ici ?", "ici", ""],
				["Mardi soir, vous avez vu quelque chose ?", "refus", "!jo_parle"],
			]},
			"ici": {"lines": ["Ici, c'est chez moi. Tant que l'agent me chasse pas."]},
			"refus": {"lines": ["J'ai rien vu. Je vois jamais rien. C'est comme ça qu'on me laisse tranquille."], "set": ["jo_refuse"]},
			"voyageur": {"lines": ["(Jo se redresse et regarde longtemps l'écran.)",
				"Lui. Le gilet orange. Il est passé deux fois.",
				"La deuxième fois, il était avec le conducteur. Le conducteur marchait tout seul, il se débattait pas. Ils sont montés vers la sortie.",
				"Je vous ai rien dit, hein."], "set": ["jo_parle"], "evidence": "temoignage_jo"},
			"deja": {"lines": ["Je vous ai déjà tout dit. Laissez-moi dormir."]},
			"karim": {"lines": ["(Il détourne les yeux.)", "Des conducteurs, j'en vois passer cent par jour."]},
			"rien": {"lines": ["Mmh. Laissez-moi dormir."]},
		},
		"show": {"photo_voyageur": [["!jo_parle", "voyageur"], ["", "deja"]], "karim": "karim", "default": "rien"},
	},
	"roche": {
		"name": "Mme Roche",
		"nodes": {
			"debut": {"lines": ["Bonsoir. Je ferme dans dix minutes, alors si c'est pour un journal, dépêchez-vous."], "goto": "hub"},
			"hub": {"choices": [
				["Vous étiez ouverte mardi soir ?", "mardi", ""],
				["Vous avez remarqué quelque chose d'inhabituel ?", "camionnette", ""],
				["Vous avez vu qui conduisait la camionnette ?", "conducteur", "roche_camionnette"],
			]},
			"mardi": {"lines": ["Comme tous les soirs, jusqu'à onze heures et quart. J'ai vu les gyrophares, après."]},
			"camionnette": {"lines": ["Une camionnette blanche, garée devant la Rotonde, vers onze heures. Pas de nom dessus, rien.",
				"Personne ne se gare là, le soir. Les livreurs, c'est le matin."],
				"set": ["roche_camionnette"], "evidence": "temoignage_roche"},
			"conducteur": {"lines": ["Non. Le moteur tournait, c'est tout. Elle est repartie vers la rue de Monceau, un peu après le quart."]},
			"karim": {"lines": ["C'est le conducteur ? Non, je l'ai pas vu. Le pauvre homme."]},
			"voyageur": {"lines": ["Un gilet orange... Il y en avait un près de la camionnette, oui. Je crois."]},
			"rien": {"lines": ["Ça, je saurais pas vous dire."]},
		},
		"show": {"karim": "karim", "photo_voyageur": "voyageur", "default": "rien"},
	},
	"gardien": {
		"name": "Le gardien",
		"nodes": {
			"debut": {"lines": ["Le parc est fermé, monsieur. Depuis dix heures et demie."], "goto": "hub"},
			"hub": {"choices": [
				["Vous étiez là mardi soir ?", "mardi", ""],
				["Vous avez vu quelqu'un sortir du métro ?", "deux_hommes", ""],
			]},
			"mardi": {"lines": ["C'est moi qui ferme les grilles. Mardi, j'ai fini tard, vers onze heures et quart."]},
			"deux_hommes": {"lines": ["Deux hommes, oui. Ils sont remontés de la station et ils sont partis vers la rue de Monceau. Pressés.",
				"L'un tenait l'autre par le bras. J'ai cru à un ivrogne."],
				"set": ["gardien_deux_hommes"], "evidence": "temoignage_gardien"},
			"karim": {"lines": ["(Il regarde la photo un moment.)",
				"C'est lui. Celui qu'on tenait par le bras. Il avait pas l'air saoul, maintenant que vous le dites."],
				"set": ["gardien_reconnait"]},
			"karim_avant": {"lines": ["Jamais vu. Enfin... je sais pas."]},
			"voyageur": {"lines": ["Le gilet orange, oui. C'était l'autre."]},
			"rien": {"lines": ["Je ferme des grilles, monsieur. Je regarde pas les papiers des gens."]},
		},
		"show": {"karim": [["gardien_deux_hommes", "karim"], ["", "karim_avant"]], "photo_voyageur": "voyageur", "default": "rien"},
	},
}
