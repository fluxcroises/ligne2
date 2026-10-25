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
