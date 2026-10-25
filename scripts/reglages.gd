extends Node
## Réglages du joueur, enregistrés dans user://reglages.cfg et appliqués au lancement.

signal changed

const PATH := "user://reglages.cfg"
## Tremblement des polygones : résolution de la grille d'accrochage des sommets.
const WOBBLE := {"Aucun": Vector2(4096, 3072), "PS1": Vector2(320, 240), "Fort": Vector2(160, 120)}

var mouse_sensitivity := 1.0     # multiplicateur de la sensibilité de base
var invert_y := false
var volume := 0.8
var hints := true                # messages d'aide de Nadia
var wobble := "PS1"
var fullscreen := false


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		mouse_sensitivity = cfg.get_value("jeu", "sensibilite", mouse_sensitivity)
		invert_y = cfg.get_value("jeu", "inverser_y", invert_y)
		volume = cfg.get_value("son", "volume", volume)
		hints = cfg.get_value("jeu", "aides", hints)
		wobble = cfg.get_value("image", "tremblement", wobble)
		fullscreen = cfg.get_value("image", "plein_ecran", fullscreen)
	apply()


func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	Enquete.hints_enabled = hints
	RenderingServer.global_shader_parameter_set("psx_resolution", WOBBLE.get(wobble, WOBBLE.PS1))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	changed.emit()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("jeu", "sensibilite", mouse_sensitivity)
	cfg.set_value("jeu", "inverser_y", invert_y)
	cfg.set_value("jeu", "aides", hints)
	cfg.set_value("son", "volume", volume)
	cfg.set_value("image", "tremblement", wobble)
	cfg.set_value("image", "plein_ecran", fullscreen)
	cfg.save(PATH)
	apply()
