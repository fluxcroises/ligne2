extends ChapitreJeu
## Le déroulé du chapitre 2 à Villiers : l'arrivée par la rame sur le quai direction Nation,
## la porte du local technique (que l'agent de sécurité ouvre quand on lui montre le
## signalement de Karim), Franck qui s'enfuit au fond de la boucle quand on approche, et la
## fin du chapitre en reprenant la 2 direction Nation, la déduction faite.

## Où l'on descend de la rame en arrivant de Monceau.
const ARRIVAL := Vector3(-6.0, Station.PY, 31.6)


func _init() -> void:
	number = 2


func _ready() -> void:
	super()
	_arrive.call_deferred()


## Première arrivée (pas un chargement) : sur le quai, au sortir de la rame.
func _arrive() -> void:
	if Enquete.flags.get("chapitre_2_arrivee", false):
		return
	Enquete.flags["chapitre_2_arrivee"] = true
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		player.global_position = ARRIVAL
		player.rotation.y = -PI / 2
	Enquete.save_game()


func _process(delta: float) -> void:
	super(delta)
	if _station.local_open != Enquete.check("local_ouvert"):
		_station.set_local_open(Enquete.check("local_ouvert"))
	_franck()
	_check_end()


## Franck guette au fond de la boucle ; quand le détective approche, il s'enfuit dans le noir.
func _franck() -> void:
	var franck: Personnage = _station.people.get("franck")
	if not franck or Enquete.check("franck_vu"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player or player.global_position.distance_to(franck.global_position) > 13.0:
		return
	Enquete.flags["franck_vu"] = true
	_station.people.erase("franck")
	var tween := create_tween()
	for p in _station.franck_escape():
		tween.tween_property(franck, "global_position", p, 1.2)
	tween.tween_callback(franck.queue_free)
	var phone := get_tree().current_scene.get_node_or_null("Telephone")
	if phone:
		phone.toast("Un homme en gilet orange s'enfuit au fond de la boucle.")


func _check_end() -> void:
	if _ended or not Enquete.check("solved:trafic"):
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var trafic: Trafic = _station.trafic
	var train := trafic.train_at(player.global_position) if player else null
	if train and train.destination == "Nation" and trafic.is_moving(train):
		_finish("Pigalle", "Le tunnel sert d'entrepôt à des objets volés, qui partent les nuits des faux trains de travaux. Karim l'avait vu et l'avait écrit à Delorme. On l'a fait taire. Franck s'est enfui.")
