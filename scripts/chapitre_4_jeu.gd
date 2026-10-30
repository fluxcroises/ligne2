extends ChapitreJeu
## Le déroulé du chapitre 4 à Jaurès : l'arrivée sur le quai direction Nation, le portail du dépôt
## (que Sami ouvre quand on lui montre le planning signé « M. D. »), et la fin du chapitre en
## reprenant la 2 direction Nation, une fois Delorme confronté et Josiane entendue.

const ARRIVAL := Vector3(-20.0, Station.PY + 12.48, 31.6)


func _init() -> void:
	number = 4


func _ready() -> void:
	super()
	_arrive.call_deferred()


func _arrive() -> void:
	if Enquete.flags.get("chapitre_4_arrivee", false):
		return
	Enquete.flags["chapitre_4_arrivee"] = true
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		player.global_position = ARRIVAL
		player.rotation.y = -PI / 2
	Enquete.save_game()


func _process(delta: float) -> void:
	super(delta)
	if _station.depot_open != Enquete.check("depot_ouvert"):
		_station.set_depot_open(Enquete.check("depot_ouvert"))
	_check_end()


func _check_end() -> void:
	if _ended or not Enquete.check("delorme_confronte has:temoignage_josiane"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var trafic: Trafic = _station.trafic
	var train := trafic.train_at(player.global_position) if player else null
	if train and train.destination == "Nation" and trafic.is_moving(train):
		_finish("Nation", "Marc Delorme invente de faux trains de travaux pour transporter le butin, et Franck Roussel les conduit. Le soir de la disparition, le locotracteur emmenait Karim vers Nation. Vivant.")
