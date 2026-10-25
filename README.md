# Ligne 2

Polar réaliste en vue subjective, style PS1, sur la ligne 2 du métro parisien.
Moteur : Godot 4.3 (rendu « Compatibility », léger et fidèle au style PS1).

## Lancer le projet

1. Installer [Godot 4.3](https://godotengine.org/download) (version standard, pas .NET).
2. Dans le gestionnaire de projets : **Importer** → choisir `project.godot`.
3. **F5** pour lancer.

## Contrôles

| Action | Clavier / souris | Manette |
| --- | --- | --- |
| Se déplacer | ZQSD (AZERTY) / WASD (QWERTY), flèches | Stick gauche |
| Regarder | Souris | Stick droit |
| Courir | Maj | Clic stick gauche |
| Examiner | E ou clic gauche | A / Croix |
| Téléphone (à venir) | Tab | Y / Triangle |
| Libérer la souris | Échap | Start |

## Où en est-on

Étape 1 du document de conception, plus une maquette du quai pour tester :

- rendu 320 × 240 agrandi sans lissage, couleurs 15 bits avec tramage, brouillard ;
- matériau PSX : sommets accrochés à la grille de l'écran, textures sans filtrage, sans gondolage ;
- joueur en vue subjective, visée d'objets et fenêtre d'examen ;
- station Monceau en maquette : voûte carrelée, deux quais, voies, têtes de tunnel,
  sièges, plaques, porte de service et badge de Karim à examiner.

Les textures sont dessinées dans le code en attendant les photos (`scripts/psx_kit.gd`).

## Organisation

| Dossier | Contenu |
| --- | --- |
| `scenes/` | `main.tscn` (scène de test), `player.tscn` |
| `scripts/` | joueur, contrôles, interface, construction de la station, outils PSX |
| `shaders/` | `psx.gdshader` (matériau), `psx_post.gdshader` (15 bits + tramage) |

## Réglages du rendu

- Tremblement des sommets : paramètre `snap_resolution` de `shaders/psx.gdshader`
  (320 = discret, 160 = très PS1).
- Profondeur des couleurs et tramage : `color_levels` et `dither_strength` dans `shaders/psx_post.gdshader`.
- Brouillard et lumière ambiante : nœud `WorldEnvironment` de `scenes/main.tscn`.
