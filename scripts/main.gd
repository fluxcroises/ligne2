extends Node
## Scène de jeu : le monde 3D est rendu en basse résolution dans le sous-écran « Monde »
## (PS1 : 320 × 240, réglable), affiché agrandi sans lissage ; les interfaces (HUD, téléphone,
## dialogues, pause) sont dessinées par-dessus à la résolution de la fenêtre, pour rester lisibles.

@onready var monde: SubViewport = $Monde
@onready var ecran: TextureRect = $Ecran


func _ready() -> void:
	ecran.texture = monde.get_texture()
	Reglages.changed.connect(_apply)
	_apply()


func _apply() -> void:
	monde.size = Reglages.RESOLUTIONS.get(Reglages.resolution, Vector2i(640, 480))


## Les entrées non utilisées par les interfaces vont au monde 3D (le détective).
func _unhandled_input(event: InputEvent) -> void:
	monde.push_input(event)
