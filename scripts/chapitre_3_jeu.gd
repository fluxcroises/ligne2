extends ChapitreJeu
## Le déroulé du chapitre 3 à Pigalle : l'arrivée par la rame, le lendemain soir, sur le quai
## direction Nation ; la fin du chapitre en reprenant la 2 direction Nation, une fois que
## Marchetti a dit d'où partent les caisses.

const ARRIVAL := Vector3(-20.0, Station.PY, 31.6)


func _init() -> void:
	number = 3


func _ready() -> void:
	super()
	_arrive.call_deferred()


func _arrive() -> void:
	if Enquete.flags.get("chapitre_3_arrivee", false):
		return
	Enquete.flags["chapitre_3_arrivee"] = true
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		player.global_position = ARRIVAL
		player.rotation.y = -PI / 2
	Enquete.save_game()


func _process(delta: float) -> void:
	super(delta)
	_check_end()


func _check_end() -> void:
	if _ended or not Enquete.check("marchetti_jaures"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var trafic: Trafic = _station.trafic
	var train := trafic.train_at(player.global_position) if player else null
	if train and train.destination == "Nation" and trafic.is_moving(train):
		_finish("Jaurès", "Marchetti écoule les objets volés que lui livre Franck Roussel, l'homme au gilet orange. Franck obéit à un chef de la maintenance. Les caisses partent du dépôt des trains de travaux, sous le viaduc de Jaurès.",
			_next_chapter)
