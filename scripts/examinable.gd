class_name Examinable
extends StaticBody3D
## Un objet que le joueur peut viser et examiner.
## Les objets importants ne brillent pas : rien ne les distingue à l'écran.

@export var title := ""
@export_multiline var description := ""
## Pièce du dossier (voir Chapitre1.EVIDENCE) ajoutée quand on photographie l'objet.
@export var evidence_id := ""
## Distance maximale pour qu'une photo de l'objet compte comme preuve.
@export var photo_range := 2.5
## Pièce ajoutée au dossier en examinant l'objet, si `examine_condition` est remplie
## (voir Enquete.check) ; sinon c'est `locked_description` qui s'affiche.
@export var examine_evidence := ""
@export var examine_condition := ""
@export_multiline var locked_description := ""


## Le texte affiché à l'examen ; applique l'effet éventuel (pièce au dossier).
func describe() -> String:
	if examine_condition != "" and not Enquete.check(examine_condition):
		return locked_description
	if examine_evidence != "" and Enquete.add_evidence(examine_evidence):
		var phone := get_tree().current_scene.get_node_or_null("Telephone")
		if phone:
			phone.toast("Ajouté au dossier : " + Chapitre1.EVIDENCE[examine_evidence].title)
	return description
