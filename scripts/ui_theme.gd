class_name UiTheme
## Style commun aux interfaces du jeu (téléphone, dialogues) : texte de 8 px, boutons sombres,
## cadre jaune autour de l'élément sélectionné.

const TEXT := Color("#e8e6df")
const DIM := Color("#8a8f99")
const ACCENT := Color("#ffbf00")
const ALERT := Color("#e0645a")


static func make() -> Theme:
	var t := Theme.new()
	t.default_font_size = 8
	t.set_stylebox("normal", "Button", box(Color("#1c2027"), Color.TRANSPARENT, 0, 2, 2))
	t.set_stylebox("hover", "Button", box(Color("#262c36"), Color.TRANSPARENT, 0, 2, 2))
	t.set_stylebox("pressed", "Button", box(Color("#2b3442"), Color.TRANSPARENT, 0, 2, 2))
	t.set_stylebox("focus", "Button", box(Color.TRANSPARENT, ACCENT, 1, 2, 2))
	t.set_stylebox("normal", "Label", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", TEXT)
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("scroll", "VScrollBar", box(Color("#1c2027")))
	t.set_stylebox("grabber", "VScrollBar", box(Color("#4a505c")))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(ACCENT))
	return t


static func box(bg: Color, border := Color.TRANSPARENT, width := 0, radius := 0, margin := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s
