extends ChapitreJeu
## Le déroulé du chapitre 1 à Monceau : horaires (rondes de Sylvain, fermeture du kiosque),
## et fin du chapitre quand le détective prend le métro direction Nation après les aveux de
## Sylvain ; on continue alors à Villiers (chapitre 2).

var _ronde := false
var _kiosk_open := true


func _init() -> void:
	number = 1


func _process(delta: float) -> void:
	var m := Enquete.minutes()
	if not Enquete.in_dialogue:
		_schedule(m)
	super(delta)
	_check_end()


# --- Horaires --------------------------------------------------------------------

static func on_ronde(m: int) -> bool:
	return m >= Chapitre1.RONDE_FIRST and (m - Chapitre1.RONDE_FIRST) % Chapitre1.RONDE_EVERY < Chapitre1.RONDE_LENGTH


func _schedule(m: int) -> void:
	var sylvain: Personnage = _station.people.get("sylvain")
	var ronde := on_ronde(m)
	if sylvain and ronde != _ronde:
		_ronde = ronde
		if ronde:
			sylvain.move_to(_station.SYLVAIN_QUAI, -PI / 2)
		else:
			sylvain.move_to(_station.SYLVAIN_GUICHET, _station.SYLVAIN_GUICHET_YAW)
		_station.loge_door.rotation.y = deg_to_rad(_station.LOGE_DOOR_OPEN) if ronde else 0.0
	if _kiosk_open and m >= Chapitre1.KIOSK_CLOSES:
		_kiosk_open = false
		var roche: Node = _station.people.get("roche")
		if roche:
			_station.people.erase("roche")
			roche.queue_free()
		_station.kiosk_shutter.show()


# --- Fin du chapitre -------------------------------------------------------------

func _check_end() -> void:
	if _ended or not Enquete.flags.get("sylvain_aveu", false):
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var trafic: Trafic = _station.trafic
	var train := trafic.train_at(player.global_position) if player else null
	if train and train.destination == "Nation" and trafic.is_moving(train):
		_finish("Villiers", "Karim n'a pas eu de malaise. Un faux agent l'a fait sortir par la porte de service, et Sylvain a regardé ailleurs pour quelques billets.",
			_next_chapter)
