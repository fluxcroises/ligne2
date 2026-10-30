extends ChapitreJeu
## Le déroulé du chapitre 5 à Nation : l'arrivée sur le quai d'arrivée, la porte de service
## (que Bruno ouvre), la grille du local 14 (Franck donne la clé), et la fin du jeu quand Karim
## est libre.

const ARRIVAL := Vector3(-20.0, Station.PY, 31.6)


func _init() -> void:
	number = 5


func _ready() -> void:
	super()
	_arrive.call_deferred()


func _arrive() -> void:
	if Enquete.flags.get("chapitre_5_arrivee", false):
		return
	Enquete.flags["chapitre_5_arrivee"] = true
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		player.global_position = ARRIVAL
		player.rotation.y = -PI / 2
	Enquete.save_game()


func _process(delta: float) -> void:
	super(delta)
	if _station.service_open != Enquete.check("porte_boucle"):
		_station.set_service_open(Enquete.check("porte_boucle"))
	if _station.niche_open != Enquete.check("franck_cede"):
		_station.set_niche_open(Enquete.check("franck_cede"))
	if not _ended and Enquete.check("karim_libre") and not Enquete.in_dialogue:
		_ended = true
		Enquete.flags["chapitre_5_fini"] = true
		Enquete.save_game()
		_on_continue = func() -> void: get_tree().change_scene_to_file("res://scenes/titre.tscn")
		_show_end_screen([["Fin", UiTheme.ACCENT], ["Nation", UiTheme.TEXT],
			["Karim est remonté à la surface à 1 h 12, appuyé sur votre épaule. Nadia l'attendait sur la place de la Nation.", UiTheme.TEXT],
			["Les photos du tunnel étaient sous le siège de la cabine du 040. Marc Delorme a été arrêté deux jours plus tard. Franck Roussel et Marchetti ont témoigné ; Sylvain a rendu ses billets.", UiTheme.TEXT],
			["Merci d'avoir joué à Ligne 2.", UiTheme.ACCENT], ["Entrée : retour au titre", UiTheme.DIM]])
